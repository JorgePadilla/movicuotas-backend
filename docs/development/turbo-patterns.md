## Turbo (Hotwire) Patterns and Best Practices

### Overview
MOVICUOTAS uses Turbo (Hotwire) for dynamic, SPA-like interactions without writing JavaScript. Turbo enables:
- **Turbo Drive**: Fast page navigation
- **Turbo Frames**: Independent page sections that update independently
- **Turbo Streams**: Real-time partial page updates (after form submissions, broadcasts, etc.)

**CRITICAL**: When replacing DOM elements, ensure all context is preserved (data attributes, IDs, classes, event listeners).

---

### Turbo Frames

**Purpose**: Isolate sections of the page that can navigate and update independently.

#### Example: Customer Search Results (Step 2)

```erb
<%# app/views/vendor/customer_search/index.html.erb %>
<div class="search-container">
  <%= turbo_frame_tag "customer_search_form" do %>
    <%= form_with url: vendor_customer_search_path, method: :get, data: { turbo_frame: "customer_search_results" } do |f| %>
      <%= f.text_field :identification_number, placeholder: "Número de Identidad", class: "form-input" %>
      <%= f.submit "Buscar en TODAS las tiendas", class: "btn-primary" %>
    <% end %>
  <% end %>

  <%= turbo_frame_tag "customer_search_results" do %>
    <%# Results will be loaded here %>
  <% end %>
</div>
```

**Controller Response:**
```ruby
# app/controllers/vendor/customer_search_controller.rb
class Vendor::CustomerSearchController < ApplicationController
  def index
    if params[:identification_number].present?
      @customer = Customer.find_by(identification_number: params[:identification_number])
      @active_loan = @customer&.loans&.active&.first

      # Render only the frame, not the full page
      render turbo_stream: turbo_stream.replace(
        "customer_search_results",
        partial: "vendor/customer_search/results",
        locals: { customer: @customer, active_loan: @active_loan }
      )
    end
  end
end
```

**Partial with Context:**
```erb
<%# app/views/vendor/customer_search/_results.html.erb %>
<%= turbo_frame_tag "customer_search_results" do %>
  <% if active_loan.present? %>
    <%# Step 3a: Cliente Bloqueado %>
    <div class="alert-error" data-customer-id="<%= customer.id %>" data-loan-id="<%= active_loan.id %>">
      <h3>Cliente tiene crédito activo</h3>
      <p>Finaliza el pago de tus Movicuotas para aplicar a más créditos!</p>
      <p>Contrato: <%= active_loan.contract_number %></p>
      <p>Sucursal: <%= active_loan.branch_number %></p>
      <%= link_to "Nueva Búsqueda", vendor_customer_search_path, class: "btn-secondary" %>
    </div>
  <% elsif customer.present? %>
    <%# Step 3b: Cliente Disponible %>
    <div class="alert-success" data-customer-id="<%= customer.id %>">
      <h3>✓ Cliente disponible para nuevo crédito</h3>
      <p>Sin créditos activos</p>
      <%= link_to "Iniciar Solicitud", new_vendor_credit_application_path(customer_id: customer.id), class: "btn-primary" %>
    </div>
  <% else %>
    <div class="alert-warning">
      <p>Cliente no encontrado</p>
    </div>
  <% end %>
<% end %>
```

**✅ CORRECT**: Frame ID matches, data attributes preserved
**❌ WRONG**: Missing `turbo_frame_tag` wrapper or different ID

---

### Turbo Streams

**Purpose**: Update multiple parts of the page after form submissions or background jobs.

#### Example: Block Device (Cobrador)

```ruby
# app/controllers/cobrador/overdue_devices_controller.rb
class Cobrador::OverdueDevicesController < ApplicationController
  def block
    @device = Device.find(params[:id])
    authorize @device, :lock?

    result = MdmBlockService.new(@device, current_user).block!

    if result[:success]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # Update device status badge
            turbo_stream.replace(
              "device_#{@device.id}_status",
              partial: "cobrador/overdue_devices/status_badge",
              locals: { device: @device.reload }
            ),
            # Update dashboard counters
            turbo_stream.replace(
              "blocked_devices_count",
              partial: "cobrador/dashboard/blocked_count",
              locals: { count: Device.locked.count }
            ),
            # Show success message
            turbo_stream.prepend(
              "flash_messages",
              partial: "shared/flash",
              locals: { message: result[:message], type: "success" }
            )
          ]
        end
        format.html { redirect_to cobrador_overdue_device_path(@device), notice: result[:message] }
      end
    else
      # Handle error...
    end
  end
end
```

**View with Turbo Stream Targets:**
```erb
<%# app/views/cobrador/overdue_devices/show.html.erb %>
<div id="flash_messages">
  <%# Flash messages will be prepended here %>
</div>

<div class="device-detail">
  <h2><%= @device.brand %> <%= @device.model %></h2>

  <div id="device_<%= @device.id %>_status">
    <%= render "cobrador/overdue_devices/status_badge", device: @device %>
  </div>

  <%= button_to "Bloquear Dispositivo",
                block_cobrador_overdue_device_path(@device),
                method: :post,
                class: "btn-danger",
                data: {
                  turbo_confirm: "¿Estás seguro de bloquear este dispositivo?",
                  turbo_method: :post
                } %>
</div>

<div class="sidebar">
  <div id="blocked_devices_count">
    <%= render "cobrador/dashboard/blocked_count", count: Device.locked.count %>
  </div>
</div>
```

**Status Badge Partial (Replaced via Turbo Stream):**
```erb
<%# app/views/cobrador/overdue_devices/_status_badge.html.erb %>
<div id="device_<%= device.id %>_status" class="status-badge">
  <% if device.locked? %>
    <span class="badge badge-red" data-status="locked">🔴 Bloqueado</span>
    <p class="text-sm">Bloqueado: <%= device.locked_at.strftime("%d/%m/%Y %H:%M") %></p>
  <% elsif device.pending_lock? %>
    <span class="badge badge-orange" data-status="pending">⏳ Pendiente de Bloqueo</span>
  <% else %>
    <span class="badge badge-green" data-status="unlocked">✅ Activo</span>
  <% end %>
</div>
```

**✅ CORRECT**:
- ID matches target (`device_#{@device.id}_status`)
- Data attributes preserved (`data-status`)
- Context maintained (device info)

**❌ WRONG**:
- Changing ID in replacement
- Missing data attributes
- Losing nested elements

---

### Turbo Stream Broadcasting (Real-time Updates)

**Use case**: Notify all cobradores when a device is blocked.

```ruby
# app/models/device.rb
class Device < ApplicationRecord
  after_update_commit :broadcast_status_change, if: :saved_change_to_lock_status?

  private

  def broadcast_status_change
    broadcast_replace_later_to(
      "cobrador_dashboard",
      target: "device_#{id}_status",
      partial: "cobrador/overdue_devices/status_badge",
      locals: { device: self }
    )
  end
end
```

**Subscribe in View:**
```erb
<%# app/views/cobrador/dashboard/index.html.erb %>
<%= turbo_stream_from "cobrador_dashboard" %>

<div class="devices-list">
  <% @overdue_devices.each do |device| %>
    <div class="device-card" data-device-id="<%= device.id %>">
      <div id="device_<%= device.id %>_status">
        <%= render "cobrador/overdue_devices/status_badge", device: device %>
      </div>
    </div>
  <% end %>
</div>
```

---

### Turbo Frame Navigation

**Example**: Vendor Workflow Step-by-Step

```erb
<%# app/views/vendor/credit_applications/new.html.erb %>
<%= turbo_frame_tag "credit_application_form" do %>
  <div class="progress-bar">
    <span class="step active">Paso 1: Datos Generales</span>
    <span class="step">Paso 2: Fotografías</span>
    <span class="step">Paso 3: Datos Laborales</span>
  </div>

  <%= form_with model: @credit_application, url: vendor_credit_applications_path, data: { turbo_frame: "credit_application_form" } do |f| %>
    <%# Step 1 fields %>
    <%= f.text_field :full_name, required: true %>
    <%= f.date_field :date_of_birth, required: true %>
    <%# ... more fields ... %>

    <%= f.submit "Siguiente →", class: "btn-primary" %>
  <% end %>
<% end %>
```

**Controller navigates to next step:**
```ruby
# app/controllers/vendor/credit_applications_controller.rb
def create
  @credit_application = CreditApplication.new(credit_application_params)

  if @credit_application.save
    # Redirect to next step, but within the same frame
    redirect_to edit_vendor_credit_application_path(@credit_application, step: 2),
                notice: "Paso 1 completado"
  else
    render :new, status: :unprocessable_entity
  end
end

def edit
  @credit_application = CreditApplication.find(params[:id])
  @step = params[:step]&.to_i || 1

  # Render specific step partial within the frame
  render partial: "vendor/credit_applications/step_#{@step}",
         locals: { credit_application: @credit_application }
end
```

---

### Testing Turbo Responses

#### Controller Tests

```ruby
# test/controllers/cobrador/overdue_devices_controller_test.rb
class Cobrador::OverdueDevicesControllerTest < ActionDispatch::IntegrationTest
  test "should block device and return turbo stream" do
    device = devices(:unlocked_overdue)

    post block_cobrador_overdue_device_path(device), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type

    # Verify turbo stream actions
    assert_match /turbo-stream action="replace" target="device_#{device.id}_status"/, response.body
    assert_match /turbo-stream action="replace" target="blocked_devices_count"/, response.body
    assert_match /turbo-stream action="prepend" target="flash_messages"/, response.body

    # Verify device was updated
    assert device.reload.locked?
  end
end
```

#### System Tests (Capybara)

```ruby
# test/system/cobrador/block_device_test.rb
class Cobrador::BlockDeviceTest < ApplicationSystemTestCase
  test "cobrador blocks device with turbo" do
    login_as users(:cobrador)
    device = devices(:unlocked_overdue)

    visit cobrador_overdue_device_path(device)

    # Verify initial state
    assert_selector "#device_#{device.id}_status", text: "Activo"

    # Click block button (triggers Turbo Stream)
    accept_confirm do
      click_button "Bloquear Dispositivo"
    end

    # Verify Turbo Stream updated the status WITHOUT full page reload
    assert_selector "#device_#{device.id}_status", text: "Pendiente de Bloqueo", wait: 2

    # Verify no full page reload occurred
    assert_no_selector "body[data-turbo-preview]"

    # Verify dashboard counter updated
    within "#blocked_devices_count" do
      assert_text "1", wait: 2
    end
  end
end
```

---

### Turbo Checklist: Post-Build Verification

After implementing Turbo features, verify:

#### ✅ Turbo Frames
- [ ] Frame IDs match between form `data-turbo-frame` and target `turbo_frame_tag`
- [ ] All replaced frames have the same ID in the replacement partial
- [ ] Data attributes are preserved when replacing frames
- [ ] Nested elements maintain their structure
- [ ] Form submissions target the correct frame
- [ ] Loading states show appropriately (`data-turbo-submits-with`)

#### ✅ Turbo Streams
- [ ] All target IDs exist in the DOM before stream action
- [ ] Multiple streams in one response have unique targets
- [ ] Stream actions (replace, update, append, prepend, remove) are appropriate
- [ ] Partials rendered by streams include necessary context
- [ ] Flash messages appear without page reload
- [ ] Counters/stats update in real-time

#### ✅ Turbo Drive
- [ ] Form submissions return correct status codes (303 redirect, 422 unprocessable)
- [ ] `turbo: false` used where necessary (file downloads, external links)
- [ ] Confirmation dialogs work (`data-turbo-confirm`)
- [ ] Browser back button works correctly
- [ ] Page caching disabled for sensitive pages (`turbo:before-cache`)

#### ✅ Context Preservation
- [ ] IDs remain consistent across updates
- [ ] CSS classes are maintained
- [ ] Data attributes (`data-*`) are not lost
- [ ] ARIA attributes preserved for accessibility
- [ ] Event listeners re-attach (use Stimulus controllers)
- [ ] Nested components maintain state

#### ✅ Error Handling
- [ ] Validation errors display inline without page reload
- [ ] Network errors show user-friendly messages
- [ ] Failed Turbo requests fallback gracefully
- [ ] `status: :unprocessable_entity` used for form errors

---

### Common Pitfalls and Solutions

#### ❌ Problem: Frame ID Mismatch
```erb
<%# WRONG %>
<%= form_with url: search_path, data: { turbo_frame: "search_results" } %>
<%= turbo_frame_tag "results" %>  <%# Different ID! %>
```

```erb
<%# CORRECT %>
<%= form_with url: search_path, data: { turbo_frame: "search_results" } %>
<%= turbo_frame_tag "search_results" %>  <%# Matching ID %>
```

#### ❌ Problem: Lost Data Attributes
```erb
<%# WRONG: Missing data attribute in replacement %>
<div id="device_123_status">
  <span>Bloqueado</span>
</div>
```

```erb
<%# CORRECT: Preserve data attributes %>
<div id="device_123_status" data-device-id="123" data-status="locked">
  <span class="badge badge-red" data-status="locked">Bloqueado</span>
</div>
```

#### ❌ Problem: Replacing Parent Instead of Target
```ruby
# WRONG: Replaces entire device card
turbo_stream.replace("device_card_#{device.id}", ...)

# CORRECT: Only replace status section
turbo_stream.replace("device_#{device.id}_status", ...)
```

---

### Stimulus Controllers (When Needed)

Use Stimulus for behavior that survives Turbo updates:

```javascript
// app/javascript/controllers/device_status_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge"]
  static values = {
    deviceId: Number,
    status: String
  }

  connect() {
    console.log(`Device ${this.deviceIdValue} connected with status: ${this.statusValue}`)
  }

  statusValueChanged() {
    // Update UI when status changes via Turbo Stream
    this.updateBadgeColor()
  }

  updateBadgeColor() {
    const colors = {
      locked: "badge-red",
      pending: "badge-orange",
      unlocked: "badge-green"
    }

    this.badgeTarget.className = `badge ${colors[this.statusValue]}`
  }
}
```

```erb
<div data-controller="device-status"
     data-device-status-device-id-value="<%= device.id %>"
     data-device-status-status-value="<%= device.lock_status %>">
  <span data-device-status-target="badge" class="badge">
    <%= device.lock_status %>
  </span>
</div>
```

---

### Performance Considerations

1. **Lazy Load Frames**: Use `loading="lazy"` for frames below the fold
2. **Cache Frame Contents**: Use `data-turbo-permanent` for elements that don't change
3. **Limit Stream Actions**: Don't send 50+ turbo streams in one response
4. **Use Broadcasts Wisely**: Don't broadcast to thousands of users simultaneously

```erb
<%# Lazy load expensive content %>
<%= turbo_frame_tag "expensive_stats",
                    src: cobrador_stats_path,
                    loading: "lazy" do %>
  <p>Cargando estadísticas...</p>
<% end %>
```

