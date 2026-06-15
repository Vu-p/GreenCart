using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GreenCart.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMealPlanCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "MealPlans",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "Minutes",
                table: "MealPlans",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Category",
                table: "MealPlans");

            migrationBuilder.DropColumn(
                name: "Minutes",
                table: "MealPlans");
        }
    }
}
