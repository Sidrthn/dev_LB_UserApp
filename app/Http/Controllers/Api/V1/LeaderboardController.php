<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Module;
use App\Models\Order;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class LeaderboardController extends Controller
{

    public function check_cod(Request $request)
    {

        $user = User::where('id', $request->user_id)->first();

        return response()->json(["cod" => $user->cod]);

    }
    public function getLeaderboard(Request $request)
    {
        $monthFilter = $request->input('month', 'current'); // Default to 'current' month

        if ($monthFilter === 'previous') {
            $startDate = Carbon::now()->subMonth()->startOfMonth();
            $endDate = Carbon::now()->subMonth()->endOfMonth();
        } else {
            $startDate = Carbon::now()->startOfMonth();
            $endDate = Carbon::now()->endOfMonth();
        }

        $modules = Module::pluck('module_name'); // Get module names
        $leaderboards = [];

        // Calculate overall leaderboard for the specified month
        $overallLeaderboard = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('order_status', 'delivered') // Filter by delivered status
            ->select('user_id', DB::raw('SUM(order_amount) AS total_amount'))
            ->groupBy('user_id')
            ->with('user:id,f_name,image')
            ->orderBy('total_amount', 'desc')
            ->get();

        $leaderboards['overall'] = $this->formatLeaderboardData($overallLeaderboard);

        // Calculate module-specific leaderboards for the specified month
        foreach ($modules as $module) {
            $moduleId = Module::where('module_name', $module)->first()->id;
            $moduleLeaderboard = Order::where('module_id', $moduleId) // Get module ID by name
                ->whereBetween('created_at', [$startDate, $endDate])
                ->where('order_status', 'delivered') // Filter by delivered status
                ->select('user_id', DB::raw('SUM(order_amount) AS total_amount'))
                ->groupBy('user_id')
                ->with('user:id,f_name,image')
                ->orderBy('total_amount', 'desc')
                ->get();

            $leaderboards[$module] = $this->formatLeaderboardData($moduleLeaderboard);
        }

        // Add user's rank and points (if authenticated) for the specified month
        $user = $request->user();
        if ($user) {
            $userLeaderboard = Order::whereBetween('created_at', [$startDate, $endDate])
                ->where('order_status', 'delivered') // Filter by delivered status
                ->select('user_id', DB::raw('SUM(order_amount) AS total_amount'))
                ->groupBy('user_id')
                ->orderBy('total_amount', 'desc')
                ->get();

            $userRank = $userLeaderboard->search(function ($order) use ($user) {
                return $order->user_id === $user->id;
            }) + 1;

            $userPoints = $user->orders()
                ->whereBetween('created_at', [$startDate, $endDate])
                ->where('order_status', 'delivered') // Filter by delivered status
                ->sum('order_amount');

            $leaderboards['user'] = [
                'rank' => $userRank,
                'points' => $userPoints,
            ];
        }

        return response()->json($leaderboards);
    }

    private function formatLeaderboardData($data)
    {
        $formattedData = [];
        $rank = 1;
        $previousPoints = null;
        $currentRank = 1;

        foreach ($data as $item) {
            // Skip entries where the user is not found
            if (!$item->user) {
                continue;
            }

            if ($previousPoints !== null && $previousPoints !== $item->total_amount) {
                $rank = $currentRank;
            }
            $formattedData[] = [
                'id' => $item->user->id,
                'rank' => $rank,
                'pic' => $item->user->image ?? null, // Assuming 'image' column exists
                'name' => $item->user->f_name ?? 'test',
                'points' => $item->total_amount ?? '',
            ];
            $previousPoints = $item->total_amount;
            $currentRank++;
        }

        return $formattedData;
    }

}
