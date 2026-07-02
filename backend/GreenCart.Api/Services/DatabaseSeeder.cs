using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Services;

public sealed class DatabaseSeeder(AppDbContext dbContext, IConfiguration configuration) : IDatabaseSeeder
{
    public async Task SeedAsync()
    {
        await SeedAdminAsync();
        await SeedProductsAsync();
        await SeedMealPlansAsync();
        await SeedSampleOrdersAsync();
    }

    private async Task SeedAdminAsync()
    {
        var adminEmail = configuration["SeedAdmin:Email"];
        var adminPassword = configuration["SeedAdmin:Password"];

        if (string.IsNullOrWhiteSpace(adminEmail) ||
            string.IsNullOrWhiteSpace(adminPassword) ||
            adminPassword.Length < 8)
        {
            return;
        }

        var normalizedAdminEmail = adminEmail.Trim().ToLowerInvariant();
        var hasAdmin = await dbContext.Users.AnyAsync(user => user.Email == normalizedAdminEmail);
        if (!hasAdmin)
        {
            dbContext.Users.Add(new User
            {
                Name = "GreenCart Admin",
                Email = normalizedAdminEmail,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword),
                Role = UserRoles.Admin
            });

            await dbContext.SaveChangesAsync();
        }
    }

    private async Task SeedProductsAsync()
    {
        var categories = new[]
        {
            new Category { Name = "Vegetables", ImageUrl = "https://images.unsplash.com/photo-1540420773420-3366772f4999" },
            new Category { Name = "Fruit", ImageUrl = "https://images.unsplash.com/photo-1619566636858-adf3ef46400b" },
            new Category { Name = "Dairy", ImageUrl = "https://images.unsplash.com/photo-1628088062854-d1870b4553da" },
            new Category { Name = "Meat", ImageUrl = "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f" },
            new Category { Name = "Pantry", ImageUrl = "https://images.unsplash.com/photo-1586201375761-83865001e31c" },
            new Category { Name = "Bakery", ImageUrl = "https://images.unsplash.com/photo-1509440159596-0249088772ff" },
            new Category { Name = "Beverages", ImageUrl = "https://images.unsplash.com/photo-1544145945-f90425340c7e" }
        };

        foreach (var category in categories)
        {
            if (!await dbContext.Categories.AnyAsync(existing => existing.Name == category.Name))
            {
                dbContext.Categories.Add(category);
            }
        }

        await dbContext.SaveChangesAsync();

        var categoryByName = await dbContext.Categories.ToDictionaryAsync(category => category.Name);
        var products = new[]
        {
            Product("Organic Spinach", "Rau chân vịt hữu cơ tươi sạch cho salad và xào.", 35000m, 42, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1576045057995-568f588f82fb", true, true),
            Product("Vine Tomatoes", "Cà chua chín cây mọng nước vị ngọt tự nhiên.", 30000m, 36, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1592924357228-91a4daadcfea", false, false),
            Product("Avocado Pack", "Bơ sáp béo ngậy chuẩn bị cho món salad và bánh mì nướng.", 60000m, 18, categoryByName["Fruit"], "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578", true, true),
            Product("Strawberries", "Dâu tây ngọt lịm tươi ngon cho món tráng miệng.", 48000m, 24, categoryByName["Fruit"], "https://images.unsplash.com/photo-1464965911861-746a04b4bca6", false, false),
            Product("TH Fresh Milk", "Sữa tươi thanh trùng TH True Milk thanh mát.", 25000m, 24, categoryByName["Dairy"], "https://images.unsplash.com/photo-1563636619-e9143da7973b", false, false),
            Product("Greek Yogurt", "Sữa chua Hy Lạp giàu protein cho bữa phụ và sinh tố.", 33000m, 31, categoryByName["Dairy"], "https://images.unsplash.com/photo-1488477181946-6428a0291777", false, true),
            Product("Chicken Breast", "Ức gà ức sạch giàu protein chuẩn bị sẵn cho bữa ăn.", 80000m, 20, categoryByName["Meat"], "https://images.unsplash.com/photo-1604503468506-a8da13d82791", false, false),
            Product("Brown Rice", "Gạo lứt nguyên cám dinh dưỡng cho bữa ăn lành mạnh.", 65000m, 44, categoryByName["Pantry"], "https://images.unsplash.com/photo-1586201375761-83865001e31c", false, false),
            Product("Sourdough Loaf", "Bánh mì men tự nhiên vỏ giòn ruột mềm thơm phức.", 50000m, 16, categoryByName["Bakery"], "https://images.unsplash.com/photo-1509440159596-0249088772ff", false, true),
            Product("Cold Pressed Juice", "Nước ép ép lạnh xanh mát từ táo, dưa chuột và chanh.", 40000m, 28, categoryByName["Beverages"], "https://images.unsplash.com/photo-1613478223719-2ab802602423", true, false),
            Product("Free Range Eggs", "Trứng gà thả rườn 10 quả giàu dinh dưỡng.", 45000m, 35, categoryByName["Dairy"], "https://images.unsplash.com/photo-1506976785307-8732e854ad03", false, true),
            Product("Carrots", "Cà rốt tươi giòn ngọt cho món súp và xào.", 22000m, 38, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1445282768818-728615cc910a", false, false),
            Product("Fresh Cilantro", "Rau mùi thơm tươi cho món súp và phở.", 13000m, 40, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1506368249639-73a05d6f6488", false, false),
            Product("Yellow Onion", "Hành tây vàng thơm cho các món hầm và xào.", 15000m, 52, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1518977676601-b53f82aba655", false, false),
            Product("Bell Pepper", "Ớt chuông tươi giòn màu sắc bắt mắt ngọt vị.", 28000m, 26, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83", false, false),
            Product("Pork Belly", "Thịt ba chỉ heo tươi ngon cho món kho tấu đậm đà.", 90000m, 18, categoryByName["Meat"], "https://images.unsplash.com/photo-1602470520998-f4a52199a3d6", false, false),
            Product("Fresh Ginger", "Gừng tươi thơm nồng cho nước dùng và món xào.", 20000m, 33, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1615485500704-8e990f9900e1", false, false),
            Product("Garlic Bulb", "Tỏi củ tươi thơm gia vị không thể thiếu cho nhà bếp.", 12000m, 55, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1615477550927-6ecb4a5a59a1", false, false),
            Product("Lime (Chanh tươi - Test 5k)", "Chanh tươi thơm mát giá đúng 5.000 VNĐ để test thanh toán PayOS.", 5000m, 100, categoryByName["Fruit"], "https://images.unsplash.com/photo-1590502593747-42a996133562", true, true),
            Product("Hành lá tươi (Test PayOS 5k)", "Hành lá tươi xanh chuẩn giá 5.000 VNĐ dùng để test nhanh luồng thanh toán.", 5000m, 100, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1506368249639-73a05d6f6488", true, true),
            Product("Organic Salmon Fillet", "Phi lê cá hồi Na Uy tươi sống giàu Omega-3 dinh dưỡng cao cấp.", 150000m, 25, categoryByName["Meat"], "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2", true, true),
            Product("Premium Beef Ribeye", "Thịt thăn lưng bò Úc tươi mềm ngọt cho món bít tết tuyệt hảo.", 220000m, 15, categoryByName["Meat"], "https://images.unsplash.com/photo-1558030006-450675393462", true, false),
            Product("Broccoli Florets", "Súp lơ xanh hữu cơ tươi giòn giàu chất xơ và vitamin C.", 45000m, 40, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1459411621453-7b03977f4bfc", true, true),
            Product("Fresh Asparagus", "Măng tây xanh Đà Lạt giòn ngọt cho món áp chảo và xào thịt bò.", 65000m, 20, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1515471209610-dae1c92d8777", false, true),
            Product("Enoki & Shiitake Mushrooms", "Nấm kim châm và nấm đông cô tươi sạch chuẩn vị lẩu và xào.", 38000m, 35, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1504544750208-dc0358e63f7f", false, false),
            Product("Sweet Corn Ears", "Ngô ngọt bắp nếp vàng ươm cho súp và salad.", 25000m, 50, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1551754655-cd27e38d2076", false, false),
            Product("Japanese Sweet Potato", "Khoai lang mật Nhật Bản thơm bùi béo ngậy.", 32000m, 45, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1596097635121-14b63b7a0c19", false, false),
            Product("Crispy Gala Apples", "Táo Gala nhập khẩu giòn ngọt đậm đà mọng nước.", 55000m, 30, categoryByName["Fruit"], "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6", true, true),
            Product("Organic Blueberries", "Việt quất hữu cơ tươi giàu chất chống oxy hóa tuyệt vời.", 89000m, 22, categoryByName["Fruit"], "https://images.unsplash.com/photo-1498557850523-fd3d118b962e", true, false),
            Product("Ripe Bananas Bunch", "Chuối tiêu chín tự nhiên giàu kali và năng lượng cho buổi sáng.", 28000m, 60, categoryByName["Fruit"], "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e", false, true),
            Product("Almond Milk Unsweetened", "Sữa hạnh nhân nguyên chất không đường tốt cho sức khỏe.", 68000m, 28, categoryByName["Beverages"], "https://images.unsplash.com/photo-1568651315184-5141c2c36691", false, true),
            Product("Cheddar Cheese Block", "Phô mai Cheddar thơm béo nguyên khối nhập khẩu.", 95000m, 18, categoryByName["Dairy"], "https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d", false, false),
            Product("Extra Virgin Olive Oil", "Dầu ô liu nguyên chất ép lạnh thượng hạng cho món salad.", 145000m, 20, categoryByName["Pantry"], "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5", true, false),
            Product("Chia Seeds Organic", "Hạt chia hữu cơ giàu Omega-3 dinh dưỡng cho sinh tố và sữa chua.", 75000m, 30, categoryByName["Pantry"], "https://images.unsplash.com/photo-1514944298352-f4d732142f74", false, true)
        };

        foreach (var product in products)
        {
            var existing = await dbContext.Products.FirstOrDefaultAsync(p => p.Name == product.Name);
            if (existing is null)
            {
                dbContext.Products.Add(product);
            }
            else
            {
                existing.Price = product.Price;
                existing.Stock = product.Stock;
                existing.Description = product.Description;
                existing.ImageUrl = product.ImageUrl;
            }
        }

        await dbContext.SaveChangesAsync();
    }

    private async Task SeedSampleOrdersAsync()
    {
        var adminEmail = configuration["SeedAdmin:Email"]?.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(adminEmail)) return;

        var adminUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == adminEmail);
        if (adminUser is null) return;

        var hasOrders = await dbContext.Orders.AnyAsync(o => o.UserId == adminUser.Id);
        if (!hasOrders)
        {
            var spinach = await dbContext.Products.FirstOrDefaultAsync(p => p.Name == "Organic Spinach");
            var lime = await dbContext.Products.FirstOrDefaultAsync(p => p.Name.Contains("Lime"));

            var cancelledOrder = new Order
            {
                OrderNumber = "GC-9001",
                UserId = adminUser.Id,
                Status = OrderStatuses.Cancelled,
                PaymentStatus = PaymentStatuses.Cancelled,
                DeliveryAddress = "221B Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh",
                DeliveryPhone = "0901234567",
                DeliverySlot = "Today, 5:00 - 7:00 PM",
                PaymentProvider = "PayOS",
                PayOsOrderCode = 900101,
                Subtotal = 35000m,
                DeliveryFee = 15000m,
                Total = 50000m,
                CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                UpdatedAt = DateTimeOffset.UtcNow.AddDays(-2)
            };
            if (spinach != null)
            {
                cancelledOrder.Items.Add(new OrderItem
                {
                    ProductId = spinach.Id,
                    ProductName = spinach.Name,
                    ImageUrl = spinach.ImageUrl,
                    UnitPrice = 35000m,
                    Quantity = 1
                });
            }

            var activeOrder = new Order
            {
                OrderNumber = "GC-9002",
                UserId = adminUser.Id,
                Status = OrderStatuses.Delivering,
                PaymentStatus = PaymentStatuses.Paid,
                DeliveryAddress = "221B Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh",
                DeliveryPhone = "0901234567",
                DeliverySlot = "Tomorrow, 8:00 - 10:00 AM",
                PaymentProvider = "PayOS",
                PayOsOrderCode = 900201,
                Subtotal = 5000m,
                DeliveryFee = 10000m,
                Total = 15000m,
                CreatedAt = DateTimeOffset.UtcNow.AddHours(-3),
                UpdatedAt = DateTimeOffset.UtcNow.AddHours(-1)
            };
            if (lime != null)
            {
                activeOrder.Items.Add(new OrderItem
                {
                    ProductId = lime.Id,
                    ProductName = lime.Name,
                    ImageUrl = lime.ImageUrl,
                    UnitPrice = 5000m,
                    Quantity = 1
                });
            }

            dbContext.Orders.AddRange(cancelledOrder, activeOrder);
            await dbContext.SaveChangesAsync();
        }
    }

    private async Task SeedMealPlansAsync()
    {
        var productByName = await dbContext.Products.ToDictionaryAsync(product => product.Name);
        var meals = new[]
        {
            Meal(
                "Sweet & Sour Garden Soup",
                "A bright vegetable soup with tomato, carrot, cilantro, and lime.",
                "https://images.unsplash.com/photo-1547592166-23ac45744acd",
                10,
                25,
                4,
                "Easy",
                "Saute onion, garlic, and ginger. Add tomato and carrots, simmer until tender, then finish with lime and cilantro.",
                true,
                Ingredient(productByName["Vine Tomatoes"], "4 medium", 1),
                Ingredient(productByName["Carrots"], "3 carrots", 2),
                Ingredient(productByName["Yellow Onion"], "1 onion", 3),
                Ingredient(productByName["Garlic Bulb"], "3 cloves", 4),
                Ingredient(productByName["Fresh Ginger"], "1 thumb", 5),
                Ingredient(productByName["Fresh Cilantro"], "1 bunch", 6),
                Ingredient(productByName["Lime"], "2 limes", 7)),
            Meal(
                "Caramelized Pork Belly Bowl",
                "Slow-braised pork belly served with brown rice and fresh greens.",
                "https://images.unsplash.com/photo-1544025162-d76694265947",
                15,
                45,
                3,
                "Medium",
                "Sear pork belly, braise with onion, garlic, and ginger until glossy. Serve over brown rice with spinach.",
                true,
                Ingredient(productByName["Pork Belly"], "600g", 1),
                Ingredient(productByName["Brown Rice"], "2 cups cooked", 2),
                Ingredient(productByName["Organic Spinach"], "2 handfuls", 3),
                Ingredient(productByName["Yellow Onion"], "1 onion", 4),
                Ingredient(productByName["Garlic Bulb"], "4 cloves", 5),
                Ingredient(productByName["Fresh Ginger"], "1 thumb", 6)),
            Meal(
                "Green Protein Breakfast Plate",
                "Eggs, avocado, sourdough, and yogurt for a balanced morning meal.",
                "https://images.unsplash.com/photo-1525351484163-7529414344d8",
                8,
                12,
                2,
                "Easy",
                "Toast sourdough, scramble eggs, slice avocado, and serve with Greek yogurt and strawberries.",
                false,
                Ingredient(productByName["Free Range Eggs"], "4 eggs", 1),
                Ingredient(productByName["Avocado Pack"], "2 avocados", 2),
                Ingredient(productByName["Sourdough Loaf"], "4 slices", 3),
                Ingredient(productByName["Greek Yogurt"], "1 cup", 4),
                Ingredient(productByName["Strawberries"], "1 punnet", 5, isOptional: true)),
            Meal(
                "Seared Norwegian Salmon & Asparagus",
                "Crispy skin salmon fillet served with tender garlic-buttered asparagus.",
                "https://images.unsplash.com/photo-1467003909585-2f8a72700288",
                10,
                15,
                2,
                "Medium",
                "Season salmon fillet with salt and pepper. Sear skin-side down in olive oil until crispy. Flip and sauté fresh asparagus with garlic until tender.",
                true,
                Ingredient(productByName["Organic Salmon Fillet"], "300g", 1),
                Ingredient(productByName["Fresh Asparagus"], "1 bunch", 2),
                Ingredient(productByName["Garlic Bulb"], "3 cloves", 3),
                Ingredient(productByName["Extra Virgin Olive Oil"], "2 tbsp", 4),
                Ingredient(productByName["Lime"], "1 lime", 5, isOptional: true)),
            Meal(
                "Pan-Seared Ribeye Steak & Broccoli",
                "Juicy premium beef ribeye steak paired with steamed green broccoli.",
                "https://images.unsplash.com/photo-1558030006-450675393462",
                10,
                12,
                2,
                "Medium",
                "Let steak rest at room temp. Sear in hot olive oil with crushed garlic cloves for 3-4 minutes per side. Serve with steamed broccoli.",
                true,
                Ingredient(productByName["Premium Beef Ribeye"], "400g", 1),
                Ingredient(productByName["Broccoli Florets"], "1 bowl", 2),
                Ingredient(productByName["Garlic Bulb"], "4 cloves", 3),
                Ingredient(productByName["Extra Virgin Olive Oil"], "2 tbsp", 4)),
            Meal(
                "Creamy Avocado & Spinach Super Salad",
                "Nutrient-dense green salad with ripe avocado, tomatoes, and organic chia seeds.",
                "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
                15,
                0,
                2,
                "Easy",
                "Wash spinach thoroughly. Dice avocado and vine tomatoes. Toss together with extra virgin olive oil and sprinkle crunchy organic chia seeds on top.",
                true,
                Ingredient(productByName["Organic Spinach"], "200g", 1),
                Ingredient(productByName["Avocado Pack"], "2 avocados", 2),
                Ingredient(productByName["Vine Tomatoes"], "3 medium", 3),
                Ingredient(productByName["Extra Virgin Olive Oil"], "2 tbsp", 4),
                Ingredient(productByName["Chia Seeds Organic"], "1 tbsp", 5)),
            Meal(
                "Japanese Sweet Potato & Enoki Stir-Fry",
                "Warm wholesome vegetable stir-fry with sweet potato and savory mushrooms.",
                "https://images.unsplash.com/photo-1540420773420-3366772f4999",
                15,
                20,
                3,
                "Easy",
                "Cube sweet potato and steam until slightly soft. Stir-fry yellow onion, carrots, enoki & shiitake mushrooms in olive oil, then combine with sweet potato.",
                false,
                Ingredient(productByName["Japanese Sweet Potato"], "300g", 1),
                Ingredient(productByName["Enoki & Shiitake Mushrooms"], "1 pack", 2),
                Ingredient(productByName["Yellow Onion"], "1 onion", 3),
                Ingredient(productByName["Carrots"], "2 carrots", 4)),
            Meal(
                "Berry & Chia Almond Pudding Bowl",
                "Refreshing antioxidant-rich dessert bowl with blueberries, strawberries, and almond milk.",
                "https://images.unsplash.com/photo-1488477181946-6428a0291777",
                10,
                5,
                2,
                "Easy",
                "Mix chia seeds with unsweetened almond milk and let chill. Top generously with fresh Greek yogurt, organic blueberries, and sliced strawberries.",
                true,
                Ingredient(productByName["Organic Blueberries"], "1 box", 1),
                Ingredient(productByName["Strawberries"], "1 punnet", 2),
                Ingredient(productByName["Chia Seeds Organic"], "3 tbsp", 3),
                Ingredient(productByName["Almond Milk Unsweetened"], "1 cup", 4),
                Ingredient(productByName["Greek Yogurt"], "1/2 cup", 5)),
            Meal(
                "Healthy Chicken Breast & Brown Rice Bowl",
                "Lean protein chicken bowl with whole grain brown rice and crunchy steamed vegetables.",
                "https://images.unsplash.com/photo-1546069901-ba9599a7e63c",
                12,
                25,
                3,
                "Easy",
                "Poach or grill seasoned chicken breast until juicy. Slice over a bed of warm brown rice alongside steamed broccoli and caramelized yellow onion.",
                true,
                Ingredient(productByName["Chicken Breast"], "500g", 1),
                Ingredient(productByName["Brown Rice"], "2 cups cooked", 2),
                Ingredient(productByName["Broccoli Florets"], "1 bowl", 3),
                Ingredient(productByName["Yellow Onion"], "1 onion", 4))
        };

        foreach (var meal in meals)
        {
            var existing = await dbContext.MealPlans.FirstOrDefaultAsync(m => m.Title == meal.Title);
            if (existing == null)
            {
                dbContext.MealPlans.Add(meal);
            }
            else
            {
                existing.Description = meal.Description;
                existing.ImageUrl = meal.ImageUrl;
                existing.PrepMinutes = meal.PrepMinutes;
                existing.CookMinutes = meal.CookMinutes;
                existing.Servings = meal.Servings;
                existing.Difficulty = meal.Difficulty;
                existing.Instructions = meal.Instructions;
                existing.IsFeatured = meal.IsFeatured;
            }
        }

        await dbContext.SaveChangesAsync();
    }

    private static MealPlan Meal(
        string title,
        string description,
        string imageUrl,
        int prepMinutes,
        int cookMinutes,
        int servings,
        string difficulty,
        string instructions,
        bool isFeatured,
        params MealIngredient[] ingredients) =>
        new()
        {
            Title = title,
            Description = description,
            ImageUrl = imageUrl,
            PrepMinutes = prepMinutes,
            CookMinutes = cookMinutes,
            Servings = servings,
            Difficulty = difficulty,
            Instructions = instructions,
            IsFeatured = isFeatured,
            Ingredients = ingredients
        };

    private static MealIngredient Ingredient(Product product, string quantityText, int sortOrder, bool isOptional = false) =>
        new()
        {
            ProductId = product.Id,
            QuantityText = quantityText,
            SortOrder = sortOrder,
            IsOptional = isOptional
        };

    private static Product Product(
        string name,
        string description,
        decimal price,
        int stock,
        Category category,
        string imageUrl,
        bool isOrganic,
        bool isDeal) =>
        new()
        {
            Name = name,
            Description = description,
            Price = price,
            Stock = stock,
            CategoryId = category.Id,
            ImageUrl = imageUrl,
            IsOrganic = isOrganic,
            IsDeal = isDeal
        };
}
