ROM.env.repositories[:default].migration do
  change do
    create_table :carrots do
      primary_key :id
      String :name
    end
  end
end
