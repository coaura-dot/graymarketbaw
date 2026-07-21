# BAWMC.net Loja — E-commerce em Sinatra + ActiveRecord

Trabalho da disciplina **Programação Web** — Instituto Federal de Goiás, Campus Anápolis.
Professor: Luiz Fernando Batista Loja.

Aplicação web de e-commerce simplificado, temática **BAWMC.net** (servidor de Minecraft),
vendendo itens de netherite full encantados, maças, tridentes, blocos de diamante/obsidiana/netherite
e kits (shulkers com armadura, ferramentas, cristais do End etc).

## Tecnologias

- Ruby + **Sinatra** (modular, `Sinatra::Base`)
- **ActiveRecord** com banco **SQLite** via *migrations*
- Templates **ERB** + formulários HTML puro + layout compartilhado (cabeçalho/rodapé)
- **RSpec** com testes de modelo, de rotas (Rack::Test) e de interface (Capybara)

## Dependências

- Ruby >= 3.0
- Bundler (`gem install bundler`)
- SQLite3 (biblioteca do sistema — no Ubuntu/Debian: `sudo apt-get install libsqlite3-dev`)

## Instalação

```bash
# 1. Extraia o zip e entre na pasta
unzip bawmc-store.zip
cd bawmc-store

# 2. Instale as dependências
bundle install
```

## Preparar o banco de dados

```bash
# Cria o arquivo do banco (se necessário)
bundle exec rake db:create

# Executa as migrations (cria as 4 tabelas: usuarios, produtos, vendas, item_vendas)
bundle exec rake db:migrate

# (Opcional, mas recomendado) Popula o banco com produtos de exemplo do BAWMC.net
bundle exec rake db:seed
```

O comando `db:seed` cria dois usuários de teste:

| Papel      | E-mail            | Senha  |
|------------|-------------------|--------|
| Vendedor   | loja@bawmc.net    | 123456 |
| Comprador  | steve@bawmc.net   | 123456 |

E cadastra 16 produtos temáticos (espadas, armaduras e machados de netherite full
encantados, maças, tridentes, blocos de diamante/obsidiana/netherite e kits em shulker box).

Para resetar tudo (apaga o banco, migra e popula novamente):

```bash
bundle exec rake db:reset
```

## Rodar o servidor

```bash
bundle exec puma config.ru
# ou
bundle exec rackup config.ru
```

A aplicação sobe em `http://localhost:9292` por padrão.

## Rodar a suíte de testes

A suíte inteira roda com um único comando:

```bash
bundle exec rspec
```

Os testes usam um banco SQLite separado (`db/test.sqlite3`), criado automaticamente a
partir de `db/schema.rb`, e cada exemplo roda dentro de uma transação que é revertida ao
final (via `database_cleaner`), então rodar os testes não afeta o banco de desenvolvimento.

A suíte está organizada em três camadas, em pastas dedicadas:

- **`spec/models/`** — valida atributos, relacionamentos, validações de presença/unicidade/formato
  e regras de negócio (ex: débito de estoque e cálculo de `valor_total` ao finalizar uma compra,
  transação que falha por inteiro se um item não puder ser reservado, sequência de status da venda).
- **`spec/routes/`** — exercita cada rota HTTP da aplicação (cadastro, login, CRUD de produtos,
  carrinho, finalização de compra, cancelamento, avanço de status), verificando código de retorno,
  redirecionamentos e o efeito real no banco de dados.
- **`spec/features/`** — simula o fluxo de uso real ponta a ponta com Capybara: um usuário se
  cadastra, um vendedor publica um produto, um comprador realiza a compra e o vendedor avança o
  status até a entrega.

## Estrutura do projeto

```
bawmc-store/
├── app.rb                  # Aplicação Sinatra (todas as rotas)
├── config.ru                # Rack entry point
├── config/environment.rb    # Conexão com o banco (ActiveRecord)
├── Rakefile                  # Tasks db:create / db:migrate / db:seed / db:reset
├── db/
│   ├── migrate/               # As 4 migrations (usuarios, produtos, vendas, item_vendas)
│   ├── schema.rb               # Schema gerado (usado também para montar o banco de testes)
│   └── seeds.rb                 # Produtos de exemplo do BAWMC.net
├── app/models/                # Usuario, Produto, Venda, ItemVenda
├── views/                      # Templates ERB (layout compartilhado + páginas)
├── public/css/style.css        # Estilo com tema Minecraft/BAWMC
└── spec/
    ├── models/                  # Testes de modelo
    ├── routes/                  # Testes de rotas/controladores
    ├── features/                 # Teste de interface (fluxo completo)
    └── support/factories.rb       # Helpers para criar usuários/produtos nos testes
```

## Modelo de dados

Segue exatamente o MER especificado no trabalho, com quatro entidades:

- **Usuario** (`id`, `nome`, `email` único, `senha_hash`, `cpf`, `telefone`) — o mesmo usuário
  pode ser vendedor (se tiver produtos cadastrados) e/ou comprador (se tiver compras realizadas);
  o papel é inferido pelas associações, não por um campo explícito.
- **Produto** (`id`, `nome`, `descricao`, `preco`, `estoque`, `vendedor_id` FK) — pertence a um
  único vendedor.
- **Venda** (`id`, `comprador_id` FK, `vendedor_id` FK, `data`, `status`, `valor_total`) —
  status restrito a `pendente`, `paga`, `enviada`, `entregue` ou `cancelada`.
- **ItemVenda** (`id`, `venda_id` FK, `produto_id` FK, `quantidade`, `preco_unitario`) — uma
  venda é composta por um ou mais itens; o preço unitário é o praticado no momento da compra.

## Regras de negócio implementadas

- E-mail obrigatório, com formato válido e único entre usuários.
- CPF obrigatório.
- Nome do produto obrigatório; preço deve ser positivo; estoque não pode ser negativo.
- Status da venda restrito aos cinco valores permitidos.
- Quantidade de cada item de venda deve ser maior que zero.
- Ao finalizar uma compra (`Venda.finalizar_compra!`), o estoque de cada produto é debitado e o
  `valor_total` é calculado automaticamente, tudo dentro de uma transação de banco que falha por
  inteiro caso algum item não possa ser reservado (estoque insuficiente).
- Cancelamento de uma compra pendente estorna o estoque reservado.
- Avanço de status da venda segue a sequência natural: pendente → paga → enviada → entregue.

## Funcionalidades por ator

**Todo usuário:** cadastro, autenticação (login/logout) e edição do próprio perfil.

**Vendedor:** cadastrar, editar, excluir e listar os próprios produtos; consultar vendas
recebidas; avançar a situação de cada venda até a entrega.

**Comprador:** buscar produtos (por nome/descrição/categoria), ver detalhes, adicionar itens ao
carrinho, finalizar a compra, listar as próprias compras e cancelar uma compra ainda pendente.

## Suíte de testes incluída

A suíte completa está em `spec/` (`spec/models`, `spec/routes`, `spec/features`,
`spec/support/factories.rb`) e foi escrita batendo exatamente com os nomes de campos,
rotas e regras de negócio do código em `app.rb` e `app/models/`. Rode
`bundle install && bundle exec rspec` para executá-la — o `spec_helper.rb` recria
automaticamente `db/test.sqlite3` a partir de `db/schema.rb` a cada execução.

## Prints das telas

> Adicione aqui os prints solicitados no trabalho (cadastro, login, listagem de produtos,
> carrinho, finalizar compra, minhas compras, vendas recebidas) após rodar a aplicação
> localmente, conforme pedido no enunciado.

## Observações

- O domínio (e-commerce de itens do servidor BAWMC.net) e o modelo de dados seguem
  exatamente o especificado no enunciado do trabalho; os únicos acréscimos são atributos
  opcionais (`categoria` e `avaliacao` em Produto, `endereco_entrega` em Venda), permitidos
  pelo enunciado.
- Os arquivos `db/*.sqlite3`, a pasta `.bundle/` e `spec/tmp/` não devem ser incluídos na
  entrega (já listados em `.gitignore`).
