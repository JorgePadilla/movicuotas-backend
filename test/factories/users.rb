FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    password { "TestPassword123!" }
    role { "vendedor" }

    factory :admin_user do
      role { "admin" }
    end

    factory :vendedor_user do
      role { "vendedor" }
      branch_number { "BR01" }
    end

    factory :cobrador_user do
      role { "cobrador" }
      branch_number { "BR01" }
    end
  end
end
