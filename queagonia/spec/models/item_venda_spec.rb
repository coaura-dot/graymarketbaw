require "spec_helper"

RSpec.describe ItemVenda do
  describe "validações" do
    it "é válido com quantidade e preco_unitario positivos" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)

      item = ItemVenda.new(venda: venda, produto: produto, quantidade: 2, preco_unitario: 10)
      expect(item).to be_valid
    end

    it "é inválido com quantidade zero ou negativa" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)

      item = ItemVenda.new(venda: venda, produto: produto, quantidade: 0, preco_unitario: 10)
      expect(item).not_to be_valid
      expect(item.errors[:quantidade]).not_to be_empty
    end

    it "é inválido com quantidade não inteira" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)

      item = ItemVenda.new(venda: venda, produto: produto, quantidade: 1.5, preco_unitario: 10)
      expect(item).not_to be_valid
    end

    it "é inválido com preco_unitario zero ou negativo" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)

      item = ItemVenda.new(venda: venda, produto: produto, quantidade: 1, preco_unitario: 0)
      expect(item).not_to be_valid
      expect(item.errors[:preco_unitario]).not_to be_empty
    end
  end

  describe "#subtotal" do
    it "multiplica quantidade pelo preço unitário" do
      vendedor = cria_usuario
      comprador = cria_usuario
      produto = cria_produto(vendedor: vendedor)
      venda = cria_venda(comprador: comprador, vendedor: vendedor)
      item = cria_item_venda(venda: venda, produto: produto, quantidade: 3, preco_unitario: 15)

      expect(item.subtotal).to eq(45)
    end
  end
end
