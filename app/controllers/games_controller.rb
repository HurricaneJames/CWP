class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy, :move]

  def move
    logger.debug("***** MOVING ***** ")
    logger.debug("    move: #{params[:move]}")
    @game.save if @game.move(params[:move])
    respond_to do |format|
      format.html { render :show }
      # need error handling, but will add when writing tests for json based javascript interface
      format.json { render :show, status: :ok, location: @game }
    end
  end

  def available_moves
    return render(json: '', status: :invalid_parameters) if (params[:game_id].blank? || params[:piece_id].blank?)
    @game = Game.where(id: params[:game_id]).first
    puts "Available Moves: #{params[:game_id]} :: #{params[:piece_id]}----- #{@game.all_legal_moves_for_piece(params[:piece_id])}"
    return render json: @game.all_legal_moves_for_piece(params[:piece_id])
  end

  # GET /games
  # GET /games.json
  def index
    @games = Game.all
  end

  # GET /games/1
  # GET /games/1.json
  def show
  end

  # GET /games/new
  def new
    @game = GameMaster.new_game
    respond_to do |format|
      if @game.save
        format.html { redirect_to @game }
        format.json { render :show, status: created, location: @game }
      else
        format.html { redirect_to games_url, 'Unable to create game.' }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /games/1/edit
  def edit
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(game_params)

    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    respond_to do |format|
      if @game.update(game_params)
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:current_state, :moves)
    end
end
