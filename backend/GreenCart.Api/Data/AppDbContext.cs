using GreenCart.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderReview> OrderReviews => Set<OrderReview>();
    public DbSet<ProductReview> ProductReviews => Set<ProductReview>();
    public DbSet<RealtimeEvent> RealtimeEvents => Set<RealtimeEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(user => user.Email).IsUnique();
            entity.HasIndex(user => user.FirebaseUid).IsUnique();
            entity.Property(user => user.Name).HasMaxLength(120).IsRequired();
            entity.Property(user => user.Email).HasMaxLength(255).IsRequired();
            entity.Property(user => user.PasswordHash).IsRequired();
            entity.Property(user => user.FirebaseUid).HasMaxLength(128);
            entity.Property(user => user.AuthProvider).HasMaxLength(32).IsRequired();
            entity.Property(user => user.Role).HasMaxLength(32).IsRequired();
            entity.Property(user => user.Phone).HasMaxLength(32);
            entity.Property(user => user.Address).HasMaxLength(500);
            entity.Property(user => user.AvatarUrl).HasMaxLength(1000);
            entity.HasMany<Cart>()
                .WithOne(cart => cart.User)
                .HasForeignKey(cart => cart.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasMany<Order>()
                .WithOne(order => order.User)
                .HasForeignKey(order => order.UserId)
                .OnDelete(DeleteBehavior.Cascade);
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

        modelBuilder.Entity<Cart>(entity =>
        {
            entity.HasIndex(cart => cart.UserId).IsUnique();
            entity.HasMany(cart => cart.Items)
                .WithOne(item => item.Cart)
                .HasForeignKey(item => item.CartId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<CartItem>(entity =>
        {
            entity.HasIndex(item => new { item.CartId, item.ProductId }).IsUnique();
            entity.HasOne(item => item.Product)
                .WithMany()
                .HasForeignKey(item => item.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.HasIndex(order => order.OrderNumber).IsUnique();
            entity.Property(order => order.OrderNumber).HasMaxLength(32).IsRequired();
            entity.Property(order => order.Status).HasMaxLength(32).IsRequired();
            entity.Property(order => order.PaymentStatus).HasMaxLength(32).IsRequired();
            entity.Property(order => order.DeliveryAddress).HasMaxLength(500).IsRequired();
            entity.Property(order => order.DeliveryPhone).HasMaxLength(32);
            entity.Property(order => order.SubstitutionPreference).HasMaxLength(500);
            entity.Property(order => order.Subtotal).HasConversion<double>();
            entity.Property(order => order.DeliveryFee).HasConversion<double>();
            entity.Property(order => order.Total).HasConversion<double>();
            entity.HasMany(order => order.Items)
                .WithOne(item => item.Order)
                .HasForeignKey(item => item.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(order => order.Review)
                .WithOne(review => review.Order)
                .HasForeignKey<OrderReview>(review => review.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OrderItem>(entity =>
        {
            entity.Property(item => item.ProductName).HasMaxLength(160).IsRequired();
            entity.Property(item => item.ImageUrl).HasMaxLength(1000).IsRequired();
            entity.Property(item => item.UnitPrice).HasConversion<double>();
            entity.HasOne(item => item.Product)
                .WithMany()
                .HasForeignKey(item => item.ProductId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<OrderReview>(entity =>
        {
            entity.HasIndex(review => review.OrderId).IsUnique();
            entity.Property(review => review.Comment).HasMaxLength(1000);
            entity.HasOne(review => review.User)
                .WithMany()
                .HasForeignKey(review => review.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasMany(review => review.ProductReviews)
                .WithOne(review => review.OrderReview)
                .HasForeignKey(review => review.OrderReviewId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ProductReview>(entity =>
        {
            entity.Property(review => review.Comment).HasMaxLength(500);
            entity.HasIndex(review => new { review.OrderReviewId, review.ProductId }).IsUnique();
            entity.HasOne(review => review.Product)
                .WithMany()
                .HasForeignKey(review => review.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RealtimeEvent>(entity =>
        {
            entity.Property(realtimeEvent => realtimeEvent.Type).HasMaxLength(120).IsRequired();
            entity.Property(realtimeEvent => realtimeEvent.Payload).HasMaxLength(4000).IsRequired();
            entity.HasIndex(realtimeEvent => realtimeEvent.OrderId);
            entity.HasIndex(realtimeEvent => realtimeEvent.UserId);
        });
    }
}
