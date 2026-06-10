using GreenCart.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(user => user.Email).IsUnique();
            entity.Property(user => user.Name).HasMaxLength(120).IsRequired();
            entity.Property(user => user.Email).HasMaxLength(255).IsRequired();
            entity.Property(user => user.PasswordHash).IsRequired();
            entity.Property(user => user.Role).HasMaxLength(32).IsRequired();
            entity.Property(user => user.Phone).HasMaxLength(32);
            entity.Property(user => user.Address).HasMaxLength(500);
            entity.Property(user => user.AvatarUrl).HasMaxLength(1000);
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasIndex(category => category.Name).IsUnique();
            entity.Property(category => category.Name).HasMaxLength(120).IsRequired();
            entity.Property(category => category.ImageUrl).HasMaxLength(1000);
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.HasIndex(product => product.Name);
            entity.Property(product => product.Name).HasMaxLength(160).IsRequired();
            entity.Property(product => product.Description).HasMaxLength(1000).IsRequired();
            entity.Property(product => product.ImageUrl).HasMaxLength(1000).IsRequired();
            entity.Property(product => product.Price).HasConversion<double>();
            entity.HasOne(product => product.Category)
                .WithMany(category => category.Products)
                .HasForeignKey(product => product.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
