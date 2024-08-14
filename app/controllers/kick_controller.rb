# frozen_string_literal: true

class KickController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    token = params[:token]

    if token == ENV['CK_TOKEN']
      BuildJob.perform_later

      render json: { success: true, message: 'job started' }
    else
      render json: { success: false, message: 'invalid token' }, status: :internal_server_error
    end
  end
end
