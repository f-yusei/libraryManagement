class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # 保存成功処理
      # セッションのリセット
      # ログイン
      # flash
      # リダイレクト
    else
      render "new", status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
