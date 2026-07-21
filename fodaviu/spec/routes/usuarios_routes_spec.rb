require "spec_helper"
require "rack/test"
require_relative "../../app"

RSpec.describe "Rotas de usuários" do
  include Rack::Test::Methods

  def app
    BawmcStore
  end

  describe "GET /cadastro" do
    it "retorna 200" do
      get "/cadastro"
      expect(last_response.status).to eq(200)
    end
  end

  describe "POST /cadastro" do
    it "cria um usuário válido, entra em sessão e redireciona para a home" do
      expect {
        post "/cadastro", nome: "Steve", email: "steve@bawmc.net", cpf: "111.111.111-11",
                           telefone: "62999990000", senha: "123456", senha_confirmacao: "123456"
      }.to change { Usuario.count }.by(1)

      expect(last_response.status).to eq(302)
      expect(last_response.location).to include("/")
      follow_redirect!
      expect(last_response.status).to eq(200)
    end

    it "não cria usuário quando a confirmação de senha não confere" do
      expect {
        post "/cadastro", nome: "Steve", email: "steve2@bawmc.net", cpf: "111.111.111-11",
                           senha: "123456", senha_confirmacao: "diferente"
      }.not_to change { Usuario.count }

      expect(last_response.status).to eq(200)
    end

    it "não cria usuário com email duplicado" do
      cria_usuario(email: "existe@bawmc.net")

      expect {
        post "/cadastro", nome: "Outro", email: "existe@bawmc.net", cpf: "222.222.222-22",
                           senha: "123456", senha_confirmacao: "123456"
      }.not_to change { Usuario.count }
    end
  end

  describe "POST /login" do
    it "autentica com credenciais corretas e redireciona" do
      cria_usuario(email: "login@bawmc.net", senha: "123456")

      post "/login", email: "login@bawmc.net", senha: "123456"
      expect(last_response.status).to eq(302)
      expect(last_response.location).to include("/")
    end

    it "rejeita credenciais inválidas" do
      cria_usuario(email: "login2@bawmc.net", senha: "123456")

      post "/login", email: "login2@bawmc.net", senha: "errada"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("inválid")
    end
  end

  describe "POST /logout" do
    it "limpa a sessão e redireciona" do
      usuario = cria_usuario(email: "logout@bawmc.net", senha: "123456")
      post "/login", email: "logout@bawmc.net", senha: "123456"

      post "/logout"
      expect(last_response.status).to eq(302)

      get "/perfil"
      follow_redirect!
      expect(last_request.url).to include("/login")
    end
  end

  describe "GET /perfil" do
    it "exige login e redireciona para /login quando não autenticado" do
      get "/perfil"
      expect(last_response.status).to eq(302)
      expect(last_response.location).to include("/login")
    end

    it "retorna 200 quando autenticado" do
      cria_usuario(email: "perfil@bawmc.net", senha: "123456")
      post "/login", email: "perfil@bawmc.net", senha: "123456"

      get "/perfil"
      expect(last_response.status).to eq(200)
    end
  end

  describe "POST /perfil" do
    it "atualiza os dados do usuário autenticado" do
      usuario = cria_usuario(email: "editar@bawmc.net", senha: "123456")
      post "/login", email: "editar@bawmc.net", senha: "123456"

      post "/perfil", nome: "Novo Nome", email: "editar@bawmc.net", cpf: usuario.cpf, telefone: "62988887777"
      expect(last_response.status).to eq(302)
      expect(usuario.reload.nome).to eq("Novo Nome")
    end
  end
end
