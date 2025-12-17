class Shared::IdentitySearchComponent < ViewComponent::Base
  def initialize(button_text: "Buscar en TODAS las tiendas", placeholder: "Número de Identidad del Cliente")
    @button_text = button_text
    @placeholder = placeholder
  end

  def call
    content_tag :div, class: "search-container max-w-2xl mx-auto" do
      form_with url: "#", method: :get, class: "space-y-4", data: { turbo_frame: "search_results" } do |f|
        concat(
          content_tag :div, class: "space-y-2" do
            concat(
              f.label :identification_number, "Número de Identidad del Cliente",
                class: "block text-lg font-semibold text-gray-800"
            )
            concat(
              content_tag :div, class: "flex gap-4" do
                concat(
                  f.text_field :identification_number,
                    placeholder: @placeholder,
                    class: "flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#125282] focus:border-transparent",
                    required: true
                )
                concat(
                  f.submit @button_text,
                    class: "px-8 py-3 bg-[#125282] hover:bg-[#0f4670] text-white font-bold rounded-lg transition duration-200 cursor-pointer"
                )
              end
            )
          end
        )
      end
    end
  end
end
