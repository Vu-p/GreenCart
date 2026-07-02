using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace GreenCart.Api.Hubs;

[Authorize]
public sealed class OrderHub : Hub
{
    public Task JoinOrder(string orderId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, OrderGroup(orderId));

    public Task LeaveOrder(string orderId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, OrderGroup(orderId));

    public Task JoinUser(string userId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, UserGroup(userId));

    public Task LeaveUser(string userId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, UserGroup(userId));

    public static string OrderGroup(string orderId) => $"order:{orderId}";
    public static string UserGroup(string userId) => $"user:{userId}";
}
