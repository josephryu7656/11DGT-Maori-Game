-- Define menu items and their prices
local menu = {
  ["coffee"] = 2.50,
  ["tea"] = 2.00,
  ["cake"] = 3.50,
  ["sandwich"] = 5.00
}

-- Function to calculate the total cost of an order
local function calculate_order_total(order)
  local total = 0
  for item, quantity in pairs(order) do
    local price = menu[item]
    if price then
      total = total + (price * quantity)
    else
      print("Error: Item '" .. item .. "' not found on menu.")
    end
  end
  return total
end

-- Function to display the order and total cost
local function display_order(order, total)
  print("Your order:")
  for item, quantity in pairs(order) do
    print(item .. ": " .. quantity)
  end
  print("Total: $" .. string.format("%.2f", total))
end

-- Simulate an order
local my_order = {
  ["coffee"] = 2,
  ["sandwich"] = 1,
  ["cake"] = 2
}

-- Calculate the order total
local order_total = calculate_order_total(my_order)

-- Display the order and total
if order_total > 0 then
  display_order(my_order, order_total)
end