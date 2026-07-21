require "spec_helper"

RSpec.describe Usuario do
  describe "validações" do
    it "é válido com atributos completos" do
      usuario = Usuario.new(nome: "Steve", email: "steve@bawmc.net", cpf: "111.111.111-11", senha: "123456")
      expect(usuario).to be_valid
    end

    it "é inválido sem nome" do
      usuario = Usuario.new(email: "steve@bawmc.net", cpf: "111.111.111-11", senha: "123456")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:nome]).not_to be_empty
    end

    it "é inválido sem cpf" do
      usuario = Usuario.new(nome: "Steve", email: "steve@bawmc.net", senha: "123456")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:cpf]).not_to be_empty
    end

    it "é inválido sem email" do
      usuario = Usuario.new(nome: "Steve", cpf: "111.111.111-11", senha: "123456")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:email]).not_to be_empty
    end

    it "é inválido com email em formato incorreto" do
      usuario = Usuario.new(nome: "Steve", email: "nao-e-email", cpf: "111.111.111-11", senha: "123456")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:email]).not_to be_empty
    end

    it "é inválido com email duplicado (case-insensitive)" do
      cria_usuario(email: "duplicado@bawmc.net")
      usuario = Usuario.new(nome: "Alex", email: "DUPLICADO@bawmc.net", cpf: "222.222.222-22", senha: "123456")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:email]).not_to be_empty
    end

    it "é inválido com senha menor que 6 caracteres na criação" do
      usuario = Usuario.new(nome: "Steve", email: "steve2@bawmc.net", cpf: "111.111.111-11", senha: "123")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:senha]).not_to be_empty
    end

    it "é inválido sem senha na criação" do
      usuario = Usuario.new(nome: "Steve", email: "steve3@bawmc.net", cpf: "111.111.111-11")
      expect(usuario).not_to be_valid
      expect(usuario.errors[:senha]).not_to be_empty
    end
  end

  describe "senha_hash" do
    it "gera um senha_hash ao salvar e não guarda a senha em texto puro" do
      usuario = cria_usuario(senha: "minhasenha")
      expect(usuario.senha_hash).to be_present
      expect(usuario.senha_hash).not_to eq("minhasenha")
    end
  end

  describe "associações" do
    it "tem muitos produtos como vendedor" do
      usuario = cria_usuario
      produto = cria_produto(vendedor: usuario)
      expect(usuario.produtos).to include(produto)
    end

    it "tem muitas compras como comprador" do
      comprador = cria_usuario
      vendedor = cria_usuario
      venda = cria_venda(comprador: comprador, vendedor: vendedor)
      expect(comprador.compras).to include(venda)
    end

    it "tem muitas vendas como vendedor" do
      comprador = cria_usuario
      vendedor = cria_usuario
      venda = cria_venda(comprador: comprador, vendedor: vendedor)
      expect(vendedor.vendas).to include(venda)
    end

    it "remove produtos, compras e vendas ao ser destruído (dependent: :destroy)" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)

      expect { vendedor.destroy }.to change { Produto.count }.by(-1).and change { Venda.count }.by(-1)
    end
  end

  describe "#vendedor? e #comprador?" do
    it "é vendedor quando possui ao menos um produto cadastrado" do
      usuario = cria_usuario
      expect(usuario.vendedor?).to be false
      cria_produto(vendedor: usuario)
      expect(usuario.vendedor?).to be true
    end

    it "é comprador quando possui ao menos uma compra realizada" do
      comprador = cria_usuario
      vendedor = cria_usuario
      expect(comprador.comprador?).to be false
      cria_venda(comprador: comprador, vendedor: vendedor)
      expect(comprador.comprador?).to be true
    end
  end

  describe ".autenticar" do
    it "retorna o usuário quando email e senha estão corretos" do
      usuario = cria_usuario(email: "auth@bawmc.net", senha: "segredo1")
      expect(Usuario.autenticar("auth@bawmc.net", "segredo1")).to eq(usuario)
    end

    it "é case-insensitive em relação ao email" do
      cria_usuario(email: "auth2@bawmc.net", senha: "segredo1")
      expect(Usuario.autenticar("AUTH2@bawmc.net", "segredo1")).to be_present
    end

    it "retorna nil quando a senha está incorreta" do
      cria_usuario(email: "auth3@bawmc.net", senha: "segredo1")
      expect(Usuario.autenticar("auth3@bawmc.net", "errada")).to be_nil
    end

    it "retorna nil quando o email não existe" do
      expect(Usuario.autenticar("inexistente@bawmc.net", "qualquer")).to be_nil
    end
  end
end
