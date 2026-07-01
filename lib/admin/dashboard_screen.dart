import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'today_present.dart';
import 'today_absent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_drawer.dart';
import '../widgets/admin_loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _totalGeofences = 0;
  int _totalEmployees = 0;
  int _todayPresent = 0;
  int _todayAbsent = 0;
  String _adminName = 'Admin';
  String _orgName = '';

  String _subscriptionStatus = 'Inactive';
  String _subscriptionExpiresAt = 'N/A';
  String _currentPlanName = 'Free / Trial';
  dynamic _subscriptionDaysLeft = 0;
  double _subscriptionPercentage = 100.0;
  bool _isExpired = true;
  String _trialPlanName = 'Trial Pack';
  String _trialPlanPrice = '0';
  
  late Razorpay _razorpay;
  int? _pendingPlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingPlanId == null) return;
    try {
      setState(() => _isLoading = true);
      final verifyResponse = await ApiService.verifySubscriptionPayment({
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
        'plan_id': _pendingPlanId,
      });
      if (verifyResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription activated successfully!')));
          _loadDashboardData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verification failed.')));
        }
      }
    } catch (e) {
      debugPrint('Verify Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet: ${response.walletName}')));
  }

  Future<void> _startTrialCheckout() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.createSubscriptionOrder();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['is_free'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Free trial activated!')));
            _loadDashboardData();
          }
          return;
        }

        _pendingPlanId = data['plan_id'];
        var options = {
          'key': data['key'],
          'amount': data['amount'],
          'name': _orgName.isNotEmpty ? _orgName : 'Company Dashboard',
          'order_id': data['order_id'],
          'description': 'Trial Pack Activation',
          'timeout': 120, // in seconds
          'prefill': {
            'contact': '', // could fetch from profile
            'email': ''
          }
        };
        _razorpay.open(options);
      } else {
        if (mounted) {
          String errMsg = 'Failed to create order.';
          try {
            final errData = json.decode(response.body);
            if (errData['message'] != null) {
              errMsg = errData['message'];
            }
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errMsg')));
        }
      }
    } catch (e) {
      debugPrint('Order Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminName = prefs.getString('user_name') ?? 'Admin';
      _orgName = prefs.getString('org_name') ?? '';

      final response = await ApiService.getAdminDashboard();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _totalGeofences = data['total_geofences'] ?? 0;
            _totalEmployees = data['total_employees'] ?? 0;
            _todayPresent = data['today_present'] ?? 0;
            _todayAbsent = data['today_absent'] ?? 0;
            
            _subscriptionStatus = data['subscription_status'] ?? 'Inactive';
            _subscriptionExpiresAt = data['subscription_expires_at'] ?? 'N/A';
            _currentPlanName = data['current_plan_name'] ?? 'Free / Trial';
            _subscriptionDaysLeft = data['subscription_days_left'] ?? 0;
            if (data['subscription_percentage'] != null) {
              _subscriptionPercentage = double.tryParse(data['subscription_percentage'].toString()) ?? 100.0;
            }
            _isExpired = data['is_expired'] ?? true;
            _trialPlanName = data['trial_plan_name']?.toString() ?? 'Trial Pack';
            _trialPlanPrice = data['trial_plan_price']?.toString() ?? '0';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark & Golden Theme Colors
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF9F1CC);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('GEOFENCE DASHBOARD', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 18)),
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: goldMain),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: goldMain),
            onPressed: _loadDashboardData,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_open, color: goldMain),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AdminDrawer(currentRoute: 'Dashboard'),
      body: Stack(
        children: [
          _isLoading
              ? const AdminLoader()
              : RefreshIndicator(
              color: bgDark,
              backgroundColor: goldMain,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A2A2A), cardDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: goldMain.withValues(alpha: 0.3), width: 1),
                        boxShadow: [
                          BoxShadow(color: goldMain.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back,", style: TextStyle(fontSize: 14, color: Colors.grey[400], letterSpacing: 1.2)),
                          const SizedBox(height: 5),
                          Text(_adminName.toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: goldLight)),
                          if (_orgName.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.business, color: goldMain, size: 14),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    _orgName, 
                                    style: const TextStyle(fontSize: 13, color: goldMain, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    _buildSubscriptionBanner(cardDark, goldMain, goldLight),
                    
                    const SizedBox(height: 35),
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: goldMain, size: 20),
                        const SizedBox(width: 8),
                        Text("KEY METRICS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    _buildKPIGrid(cardDark, goldMain, goldLight),
                    
                    const SizedBox(height: 35),
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: goldMain, size: 20),
                        const SizedBox(width: 8),
                        Text("QUICK ACTIONS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    _buildActionCard(
                      title: "Today's Present",
                      subtitle: "Monitor active field agents",
                      icon: Icons.how_to_reg,
                      cardColor: cardDark,
                      accentColor: goldMain,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayPresentScreen()));
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildActionCard(
                      title: "Today's Absent",
                      subtitle: "Review missing attendance",
                      icon: Icons.person_off,
                      cardColor: cardDark,
                      accentColor: Colors.redAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayAbsentScreen()));
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            if (_isExpired || _subscriptionStatus.toLowerCase() == 'inactive')
              _buildSubscriptionBlockerOverlay(goldMain),
        ],
      ),
      ),
    );
  }

  Widget _buildSubscriptionBlockerOverlay(Color accentColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.85), // Dark opaque background
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock, size: 60, color: accentColor),
              const SizedBox(height: 20),
              const Text(
                "Active Subscription Required",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                "To continue managing your organization seamlessly, please activate a subscription plan or try our trial plan.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse('http://geofence.sumatrasales.com/login');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Go to Website to Upgrade", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _startTrialCheckout,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Go with $_trialPlanName (₹$_trialPlanPrice)", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(Color cardColor, Color accentColor, Color textColor) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKPICard("Total Staff", _totalEmployees.toString(), Icons.people_alt_outlined, cardColor, accentColor, textColor),
        _buildKPICard("Geofences", _totalGeofences.toString(), Icons.radar_outlined, cardColor, accentColor, textColor),
        _buildKPICard("Present", _todayPresent.toString(), Icons.check_circle_outline, cardColor, accentColor, textColor),
        _buildKPICard("Absent", _todayAbsent.toString(), Icons.highlight_off, cardColor, Colors.redAccent, textColor),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color cardColor, Color accentColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Icon(Icons.arrow_outward, color: Colors.grey[700], size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
              const SizedBox(height: 2),
              Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color cardColor, required Color accentColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[850]!, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.2), accentColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Color(0xFFD4AF37), size: 14),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSubscriptionBanner(Color cardColor, Color accentColor, Color textColor) {
    bool isActive = _subscriptionStatus.toLowerCase() == 'active';
    Color statusColor = isActive ? Colors.greenAccent : Colors.redAccent;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SUBSCRIPTION",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _subscriptionStatus.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Plan", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const SizedBox(height: 4),
                  Text(_currentPlanName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Expires On", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const SizedBox(height: 4),
                  Text(_subscriptionExpiresAt, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
            ],
          ),
          if (!_isExpired && _subscriptionStatus.toLowerCase() == 'active') ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Progress", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                Text("$_subscriptionDaysLeft Days Left", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _subscriptionPercentage / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: _subscriptionPercentage > 90 ? Colors.redAccent : (_subscriptionPercentage > 70 ? Colors.orangeAccent : Colors.greenAccent),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
