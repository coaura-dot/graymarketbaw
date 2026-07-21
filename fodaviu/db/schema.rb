ActiveRecord::Schema.define(version: 2026_06_01_000004) do
  create_table "usuarios", force: :cascade do |t|
    t.string "nome", null: false
    t.string "email", null: false
    t.string "senha_hash", null: false
    t.string "cpf", null: false
    t.string "telefone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_usuarios_on_email", unique: true
  end

  create_table "produtos", force: :cascade do |t|
    t.string "nome", null: false
    t.string "descricao"
    t.decimal "preco", precision: 10, scale: 2, null: false
    t.integer "estoque", default: 0, null: false
    t.integer "vendedor_id", null: false
    t.string "categoria"
    t.decimal "avaliacao", precision: 3, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vendedor_id"], name: "index_produtos_on_vendedor_id"
  end

  create_table "vendas", force: :cascade do |t|
    t.integer "comprador_id", null: false
    t.integer "vendedor_id", null: false
    t.date "data", null: false
    t.string "status", default: "pendente", null: false
    t.decimal "valor_total", precision: 10, scale: 2, default: "0.0", null: false
    t.string "endereco_entrega"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comprador_id"], name: "index_vendas_on_comprador_id"
    t.index ["vendedor_id"], name: "index_vendas_on_vendedor_id"
  end

  create_table "item_vendas", force: :cascade do |t|
    t.integer "venda_id", null: false
    t.integer "produto_id", null: false
    t.integer "quantidade", null: false
    t.decimal "preco_unitario", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produto_id"], name: "index_item_vendas_on_produto_id"
    t.index ["venda_id"], name: "index_item_vendas_on_venda_id"
  end

  add_foreign_key "produtos", "usuarios", column: "vendedor_id"
  add_foreign_key "vendas", "usuarios", column: "comprador_id"
  add_foreign_key "vendas", "usuarios", column: "vendedor_id"
  add_foreign_key "item_vendas", "vendas"
  add_foreign_key "item_vendas", "produtos"
end