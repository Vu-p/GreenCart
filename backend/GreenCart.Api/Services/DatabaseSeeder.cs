using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Services;

public sealed class DatabaseSeeder(AppDbContext dbContext, IConfiguration configuration) : IDatabaseSeeder
{
    public async Task SeedAsync()
    {
        await EnsureWeek2TablesAsync();
        await SeedAdminAsync();
        await SeedProductsAsync();
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

        var hasAdmin = await dbContext.Users.AnyAsync(user => user.Email == adminEmail);
        if (!hasAdmin)
        {
            dbContext.Users.Add(new User
            {
                Name = "GreenCart Admin",
                Email = adminEmail,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword),
                Role = UserRoles.Admin
            });

            await dbContext.SaveChangesAsync();
        }
    }

    private async Task SeedProductsAsync()
    {
        if (await dbContext.Products.AnyAsync())
        {
            return;
        }

        var categories = new[]
        {
            new Category { Name = "Vegetables", ImageUrl = "https://images.unsplash.com/photo-1540420773420-3366772f4999" },
            new Category { Name = "Fruit", ImageUrl = "https://images.unsplash.com/photo-1619566636858-adf3ef46400b" },
            new Category { Name = "Dairy", ImageUrl = "https://images.unsplash.com/photo-1628088062854-d1870b4553da" },
            new Category { Name = "Meat", ImageUrl = "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f" },
            new Category { Name = "Pantry", ImageUrl = "https://images.unsplash.com/photo-1586201375761-83865001e31c" }
        };

        dbContext.Categories.AddRange(categories);
        await dbContext.SaveChangesAsync();

        var categoryByName = categories.ToDictionary(category => category.Name);
        dbContext.Products.AddRange(
            Product("Organic Spinach", "Tender organic spinach leaves for salads, smoothies, and quick stir-fries.", 3.49m, 42, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1576045057995-568f588f82fb", true, true),
            Product("Vine Tomatoes", "Juicy vine-ripened tomatoes picked for bright flavor and firm texture.", 2.99m, 36, categoryByName["Vegetables"], "https://images.unsplash.com/photo-1592924357228-91a4daadcfea", false, false),
            Product("Avocado Pack", "Creamy avocados ready for toast, salads, and fresh bowls.", 5.99m, 18, categoryByName["Fruit"], "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578", true, true),
            Product("Strawberries", "Sweet strawberries packed fresh for desserts and breakfast.", 4.79m, 24, categoryByName["Fruit"], "https://images.unsplash.com/photo-1464965911861-746a04b4bca6", false, false),
            Product("TH Fresh Milk", "Pasteurized fresh milk with a clean, naturally creamy taste.", 2.49m, 0, categoryByName["Dairy"], "https://images.unsplash.com/photo-1563636619-e9143da7973b", false, false),
            Product("Greek Yogurt", "High-protein plain yogurt for snacks, bowls, and smoothies.", 3.29m, 31, categoryByName["Dairy"], "https://images.unsplash.com/photo-1488477181946-6428a0291777", false, true),
            Product("Chicken Breast", "Lean chicken breast trimmed and ready for meal prep.", 7.99m, 20, categoryByName["Meat"], "https://images.unsplash.com/photo-1604503468506-a8da13d82791", false, false),
            Product("Brown Rice", "Nutty whole grain rice for healthy weekly cooking.", 6.49m, 44, categoryByName["Pantry"], "https://images.unsplash.com/photo-1586201375761-83865001e31c", false, false));

        await dbContext.SaveChangesAsync();
    }

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

    private async Task EnsureWeek2TablesAsync()
    {
        await dbContext.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS "Categories" (
                "Id" TEXT NOT NULL CONSTRAINT "PK_Categories" PRIMARY KEY,
                "Name" TEXT NOT NULL,
                "ImageUrl" TEXT NULL
            );
            """);

        await dbContext.Database.ExecuteSqlRawAsync("""
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_Categories_Name" ON "Categories" ("Name");
            """);

        await dbContext.Database.ExecuteSqlRawAsync("""
            CREATE TABLE IF NOT EXISTS "Products" (
                "Id" TEXT NOT NULL CONSTRAINT "PK_Products" PRIMARY KEY,
                "Name" TEXT NOT NULL,
                "Description" TEXT NOT NULL,
                "Price" REAL NOT NULL,
                "Stock" INTEGER NOT NULL,
                "ImageUrl" TEXT NOT NULL,
                "CategoryId" TEXT NOT NULL,
                "IsOrganic" INTEGER NOT NULL,
                "IsDeal" INTEGER NOT NULL,
                CONSTRAINT "FK_Products_Categories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "Categories" ("Id") ON DELETE RESTRICT
            );
            """);

        await dbContext.Database.ExecuteSqlRawAsync("""
            CREATE INDEX IF NOT EXISTS "IX_Products_CategoryId" ON "Products" ("CategoryId");
            """);

        await dbContext.Database.ExecuteSqlRawAsync("""
            CREATE INDEX IF NOT EXISTS "IX_Products_Name" ON "Products" ("Name");
            """);
    }
}
