set -e 
echo "Rodando migrations"
bundle exec rails db:migrate
echo "Iniciando puma"
exec bundle exec puma -C config/puma.rb 