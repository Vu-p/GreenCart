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
            Product("Organic Spinach", "Tender organic spinach leaves for salads, smoothies, and quick stir-fries.", 3.49m, 42, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1576045057995-568f588f82fb", true, true),
            Product("Vine Tomatoes", "Juicy vine-ripened tomatoes picked for bright flavor and firm texture.", 2.99m, 36, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1592924357228-91a4daadcfea", false, false),
            Product("Avocado Pack", "Creamy avocados ready for toast, salads, and fresh bowls.", 5.99m, 18, categoryByName["Fruit"], "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578", true, true),
            Product("Strawberries", "Sweet strawberries packed fresh for desserts and breakfast.", 4.79m, 24, categoryByName["Fruit"], "https://images.unsplash.com/photo-1464965911861-746a04b4bca6", false, false),
            Product("TH Fresh Milk", "Pasteurized fresh milk with a clean, naturally creamy taste.", 2.49m, 24, categoryByName["Dairy"], "https://images.unsplash.com/photo-1563636619-e9143da7973b", false, false),
            Product("Greek Yogurt", "High-protein plain yogurt for snacks, bowls, and smoothies.", 3.29m, 31, categoryByName["Dairy"], "https://images.unsplash.com/photo-1488477181946-6428a0291777", false, true),
            Product("Chicken Breast", "Lean chicken breast trimmed and ready for meal prep.", 7.99m, 20, categoryByName["Meat"], "https://images.unsplash.com/photo-1604503468506-a8da13d82791", false, false),
            Product("Brown Rice", "Nutty whole grain rice for healthy weekly cooking.", 6.49m, 44, categoryByName["Pantry"], "https://images.unsplash.com/photo-1586201375761-83865001e31c", false, false),
            Product("Sourdough Loaf", "Naturally leavened bread with a crisp crust and soft center.", 4.99m, 16, categoryByName["Bakery"], "https://images.unsplash.com/photo-1509440159596-0249088772ff", false, true),
            Product("Cold Pressed Juice", "Bright green juice with apple, cucumber, spinach, and lime.", 3.99m, 28, categoryByName["Beverages"], "https://images.unsplash.com/photo-1613478223719-2ab802602423", true, false),
            Product("Free Range Eggs", "Dozen free range eggs for breakfast, baking, and weekly staples.", 4.49m, 35, categoryByName["Dairy"], "https://images.unsplash.com/photo-1506976785307-8732e854ad03", false, true),
            Product("Carrots", "Crunchy sweet carrots for soups, roasting, and lunch bowls.", 2.19m, 38, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1445282768818-728615cc910a", false, false),
            Product("Fresh Cilantro", "Bright cilantro bunch for soups, salads, and fresh garnish.", 1.29m, 40, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1506368249639-73a05d6f6488", false, false),
            Product("Yellow Onion", "Aromatic yellow onions for braises, soups, and savory bases.", 1.49m, 52, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1518977676601-b53f82aba655", false, false),
            Product("Bell Pepper", "Crisp bell peppers with bright color and sweet flavor.", 2.79m, 26, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83", false, false),
            Product("Pork Belly", "Rich pork belly slices for slow braises and caramelized dishes.", 8.99m, 18, categoryByName["Meat"], "https://images.unsplash.com/photo-1602470520998-f4a52199a3d6", false, false),
            Product("Fresh Ginger", "Fragrant ginger root for soups, marinades, and stir-fries.", 1.99m, 33, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1615485500704-8e990f9900e1", false, false),
            Product("Garlic Bulb", "Fresh garlic bulbs for seasoning sauces, soups, and roasted meals.", 1.19m, 55, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1615477550927-6ecb4a5a59a1", false, false),
            Product("Lime", "Juicy limes for dressings, soups, and bright finishing flavor.", 0.79m, 60, categoryByName["Fruit"], "https://images.unsplash.com/photo-1590502593747-42a996133562", false, false)
        };

        foreach (var product in products)
        {
            if (!await dbContext.Products.AnyAsync(existing => existing.Name == product.Name))
            {
                dbContext.Products.Add(product);
            }
        }

        await dbContext.SaveChangesAsync();
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
                Ingredient(productByName["Strawberries"], "1 punnet", 5, isOptional: true))
        };

        var existingTitleList = await dbContext.MealPlans
            .Select(meal => meal.Title)
            .ToListAsync();
        var existingTitles = existingTitleList.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var missingMeals = meals.Where(meal => !existingTitles.Contains(meal.Title));

        dbContext.MealPlans.AddRange(missingMeals);
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
