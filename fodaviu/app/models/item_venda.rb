class ItemVenda < ActiveRecord::Base
  belongs_to :venda, inverse_of: :item_vendas
  belongs_to :produto

  validates :quantidade, numericality: { greater_than: 0, only_integer: true }
  validates :preco_unitario, numericality: { greater_than: 0 }

  def subtotal
    quantidade * preco_unitario
  end
end
