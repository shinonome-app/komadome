# frozen_string_literal: true

class KickController < ApplicationController
  protect_from_forgery except: :create

  def create
    token = params[:token]

    if token != ENV['CK_TOKEN']
      render json: {success: false, message: "invalid token"}, status: 500
    else
      BuildJob.perform_now

      render json: {success: true, message: "job started"}
    end
  end
end
