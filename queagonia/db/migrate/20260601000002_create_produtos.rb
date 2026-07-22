class CreateProdutos < ActiveRecord::Migration[7.1]
  def change
    create_table :produtos do |t|
      t.string :nome, null: false
      t.string :descricao
      t.decimal :preco, precision: 10, scale: 2, null: false
      t.integer :estoque, null: false, default: 0
      t.references :vendedor, null: false, foreign_key: { to_table: :usuarios }
      t.string :categoria
      t.decimal :avaliacao, precision: 3, scale: 2

      t.timestamps
    end
  end
end
