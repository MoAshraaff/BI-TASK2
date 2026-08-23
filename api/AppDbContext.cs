using Microsoft.EntityFrameworkCore;
using SalesBuzz.Shared.Data;

namespace api;

public class AppDbContext : SalesBuzzDbContextBase
{
    public AppDbContext(DbContextOptions<AppDbContext> options, ICurrentBUContext current)
        : base(options, current)
    {
    }
}
