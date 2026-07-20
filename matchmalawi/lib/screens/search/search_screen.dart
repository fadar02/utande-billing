import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _recentSearches = [];
  bool _hasSearched = false;

  String? _filterDistrict;
  RangeValues _ageRange = const RangeValues(18, 40);
  final List<String> _filterInterests = [];
  String? _filterReligion;
  String? _filterOccupation;
  String? _filterEducation;
  String? _filterRelationshipType;

  @override
  void initState() {
    super.initState();
    _recentSearches = [
      'Lilongwe',
      'Blantyre',
      'Teacher',
      'Reading',
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _hasSearched = true;
      if (!_recentSearches.contains(query.trim())) {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      }
    });

    _focusNode.unfocus();
  }

  void _applyFilters() {
    final auth = context.read<AuthProvider>();
    final discovery = context.read<DiscoveryProvider>();
    final user = auth.user;
    if (user == null) return;

    final data = {
      'ageRangeMin': _ageRange.start.round().toString(),
      'ageRangeMax': _ageRange.end.round().toString(),
      'distancePreference': _filterDistrict ?? user.distancePreference,
      'religion': _filterReligion,
      'occupation': _filterOccupation ?? '',
      'education': _filterEducation ?? '',
      'relationshipType': _filterRelationshipType,
    };

    auth.updateProfile(data).then((success) {
      if (success && mounted) {
        discovery.loadUsers(auth.user!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filters applied'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context);
      }
    });
  }

  void _toggleFilterInterest(String interest) {
    setState(() {
      if (_filterInterests.contains(interest)) {
        _filterInterests.remove(interest);
      } else {
        _filterInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _hasSearched ? _buildResults() : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search by name, district, interest...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary),
                  onPressed: () => _showFilterSheet(),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () => setState(() => _recentSearches.clear()),
                child: const Text('Clear All', style: TextStyle(color: AppTheme.primaryColor)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, color: AppTheme.textSecondary, size: 20),
                title: Text(search, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.textHint),
                  onPressed: () => setState(() => _recentSearches.removeAt(index)),
                ),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Consumer<DiscoveryProvider>(
      builder: (context, discovery, _) {
        if (discovery.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final users = discovery.users;
        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppTheme.textHint),
                SizedBox(height: 16),
                Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                SizedBox(height: 8),
                Text('Try adjusting your filters', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/user-profile', arguments: user),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    user.mainPhoto.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.mainPhoto,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                    if (user.verified)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 12),
                              SizedBox(width: 2),
                              Text('Verified', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          user.district,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.primaryLight,
      child: const Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
    );
  }

  void _showFilterSheet() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _filterDistrict = user.distancePreference != 'Anywhere in Malawi' ? user.distancePreference : null;
      _ageRange = RangeValues(
        double.tryParse(user.ageRangeMin ?? '18') ?? 18,
        double.tryParse(user.ageRangeMax ?? '40') ?? 40,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filterDistrict = null;
                          _ageRange = const RangeValues(18, 40);
                          _filterInterests.clear();
                          _filterReligion = null;
                          _filterOccupation = null;
                          _filterEducation = null;
                          _filterRelationshipType = null;
                        });
                      },
                      child: const Text('Reset', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFilterDistrict(),
                const SizedBox(height: 20),
                _buildFilterAgeRange(),
                const SizedBox(height: 20),
                _buildFilterChips('Religion', UserModel.religionsList, _filterReligion, (v) {
                  setState(() => _filterReligion = _filterReligion == v ? null : v);
                }),
                const SizedBox(height: 20),
                _buildFilterChips('Occupation', UserModel.occupationsList, _filterOccupation, (v) {
                  setState(() => _filterOccupation = _filterOccupation == v ? null : v);
                }),
                const SizedBox(height: 20),
                _buildFilterChips('Education', UserModel.educationList, _filterEducation, (v) {
                  setState(() => _filterEducation = _filterEducation == v ? null : v);
                }),
                const SizedBox(height: 20),
                _buildFilterInterests(),
                const SizedBox(height: 20),
                _buildFilterRelationshipType(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterDistrict() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('District', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _filterDistrict,
              hint: const Text('Any district', style: TextStyle(color: AppTheme.textHint)),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Any district')),
                ...UserModel.districts.map((d) => DropdownMenuItem<String>(value: d, child: Text(d))),
              ],
              onChanged: (v) => setState(() => _filterDistrict = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAgeRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Age Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 60,
          divisions: 42,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.dividerColor,
          labels: RangeLabels(_ageRange.start.round().toString(), _ageRange.end.round().toString()),
          onChanged: (v) => setState(() => _ageRange = v),
        ),
      ],
    );
  }

  Widget _buildFilterChips(String label, List<String> options, String? selected, ValueChanged<String> onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onToggle(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Interests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserModel.interestsList.map((interest) {
            final isSelected = _filterInterests.contains(interest);
            return GestureDetector(
              onTap: () => _toggleFilterInterest(interest),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(interest, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 13)),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check, size: 14, color: Colors.white),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterRelationshipType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Relationship Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: UserModel.relationshipTypes.map((type) {
            final isSelected = _filterRelationshipType == type;
            return GestureDetector(
              onTap: () => setState(() => _filterRelationshipType = isSelected ? null : type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor),
                ),
                child: Text(type, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
