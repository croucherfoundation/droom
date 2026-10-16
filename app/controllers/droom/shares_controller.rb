module Droom
  class SharesController < Droom::DroomController
    before_action :authenticate_user!, except: [:show]

    # Token-based auto-login link from share notification email
    def show
      share = Droom::Share.find_by(token: params[:id])
      if share.nil?
        set_alert(t("notifications.generic.share_link_invalid_or_expired"))
        redirect_to root_path and return
      end

      sign_in(share.shared_with)

      if share.shareable_type == 'Droom::Folder'
        redirect_to folder_path(share.shareable)
      else
        redirect_to folder_document_path(share.shareable.folder, share.shareable)
      end
    end

    def create
      shareable = find_shareable
      user_ids = Array(params[:user_ids]).map(&:to_i).uniq

      created = []
      user_ids.each do |uid|
        next if uid == current_user.id
        share = shareable.shares.find_or_initialize_by(shared_with_id: uid)
        if share.new_record?
          share.shared_by = current_user
          share.save
          if share.persisted?
            created << share
            Droom::ShareMailer.share_notification(share).deliver_later
          end
        end
      end

      render json: { created: created.size, shares: shareable.shares.includes(:shared_with).map { |s| share_json(s) } }
    end

    def destroy
      share = Droom::Share.find(params[:id])
      unless current_user.admin? || share.shared_by_id == current_user.id
        head :forbidden and return
      end
      share.destroy
      head :ok
    end

    # Returns current recipients for a shareable item (used by the modal)
    def recipients
      shareable = find_shareable
      shares = shareable.shares.includes(:shared_with)
      render json: {
        shares: shares.map { |s| share_json(s) },
        data_room: shareable.respond_to?(:data_room?) ? shareable.data_room? : false
      }
    end

    private

    def find_shareable
      klass = params[:shareable_type].safe_constantize
      raise ActiveRecord::RecordNotFound unless klass && %w[Droom::Document Droom::Folder].include?(klass.to_s)
      record = klass.find_by!(uid: params[:shareable_id])
      authorize! :read, record
      record
    end

    def share_json(share)
      {
        id: share.id,
        user_id: share.shared_with_id,
        name: share.shared_with.name,
        email: share.shared_with.email,
        avatar_url: share.shared_with.thumbnail
      }
    end
  end
end
