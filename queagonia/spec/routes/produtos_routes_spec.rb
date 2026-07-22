require "spec_helper"
require "rack/test"
require_relative "../../app"

RSpec.describe "Rotas de produtos" do
  include Rack::Test::Methods

  def app
    BawmcStore
  end

  def login(email, senha)
    post "/login", email: email, senha: senha
  end

  describe "GET /" do
    it "lista produtos e retorna 200" do
      vendedor = cria_usuario
      cria_produto(vendedor: vendedor, nome: "Espada de Netherite")

      get "/"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Espada de Netherite")
    end

    it "filtra produtos pela busca" do
      vendedor = cria_usuario
      cria_produto(vendedor: vendedor, nome: "Espada de Netherite")
      cria_produto(vendedor: vendedor, nome: "Tridente do Vazio")

      get "/", q: "tridente"
      expect(last_response.body).to include("Tridente do Vazio")
      expect(last_response.body).not_to include("Espada de Netherite")
    end
  end

  describe "GET /produtos/:id" do
    it "retorna 200 para produto existente" do
      vendedor = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      get "/produtos/#{produto.id}"
      expect(last_response.status).to eq(200)
    end

    it "retorna 404 para produto inexistente" do
      get "/produtos/999999"
      expect(last_response.status).to eq(404)
    end
  end

  describe "GET /meus_produtos e /produtos/novo" do
    it "exigem login" do
      get "/meus_produtos"
      expect(last_response.status).to eq(302)

      get "/produtos/novo"
      expect(last_response.status).to eq(302)
    end
  end

  describe "POST /produtos" do
    it "cria um produto para o vendedor autenticado" do
      vendedor = cria_usuario(email: "vend@bawmc.net", senha: "123456")
      login("vend@bawmc.net", "123456")

      expect {
        post "/produtos", nome: "Machado de Netherite", descricao: "Full encantado",
                           preco: "45.50", estoque: "3", categoria: "Netherite"
      }.to change { Produto.count }.by(1)

      expect(last_response.status).to eq(302)
      expect(vendedor.produtos.last.nome).to eq("Machado de Netherite")
    end

    it "não cria produto com preço inválido" do
      cria_usuario(email: "vend2@bawmc.net", senha: "123456")
      login("vend2@bawmc.net", "123456")

      expect {
        post "/produtos", nome: "Item Ruim", preco: "0", estoque: "1"
      }.not_to change { Produto.count }
      expect(last_response.status).to eq(200)
    end
  end

  describe "POST /produtos/:id (editar)" do
    it "atualiza um produto do próprio vendedor" do
      vendedor = cria_usuario(email: "editor@bawmc.net", senha: "123456")
      produto = cria_produto(vendedor: vendedor, nome: "Nome Antigo")
      login("editor@bawmc.net", "123456")

      post "/produtos/#{produto.id}", nome: "Nome Novo", descricao: produto.descricao,
                                       preco: produto.preco, estoque: produto.estoque
      expect(last_response.status).to eq(302)
      expect(produto.reload.nome).to eq("Nome Novo")
    end

    it "retorna 404 ao tentar editar produto de outro vendedor" do
      dono = cria_usuario
      produto = cria_produto(vendedor: dono)
      cria_usuario(email: "intruso@bawmc.net", senha: "123456")
      login("intruso@bawmc.net", "123456")

      post "/produtos/#{produto.id}", nome: "Hackeado"
      expect(last_response.status).to eq(404)
    end
  end

  describe "POST /produtos/:id/excluir" do
    it "remove um produto do próprio vendedor" do
      vendedor = cria_usuario(email: "remove@bawmc.net", senha: "123456")
      produto = cria_produto(vendedor: vendedor)
      login("remove@bawmc.net", "123456")

      expect {
        post "/produtos/#{produto.id}/excluir"
      }.to change { Produto.count }.by(-1)
      expect(last_response.status).to eq(302)
    end
  end
end
