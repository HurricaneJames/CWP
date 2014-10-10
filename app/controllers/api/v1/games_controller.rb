class Api::V1::GamesController < Api::V1::BaseController
  def available_moves
    return render(json: '', status: :invalid_parameters) if (params[:game_id].blank? || params[:piece_id].blank?)
    @game = Game.where(id: params[:game_id]).first
    return render json: @game.all_legal_moves_for_piece(params[:piece_id])
  end
end
