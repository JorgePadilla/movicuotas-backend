FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    password { "TestPassword123!" }
    role { "supervisor" }

    factory :admin_user do
      role { "admin" }
    end

    factory :supervisor_user do
      role { "supervisor" }
      branch_number { "BR01" }
    end

    factory :vendedor_user do
      role { "vendedor" }
      branch_number { "BR01" }
    end
  end
end
