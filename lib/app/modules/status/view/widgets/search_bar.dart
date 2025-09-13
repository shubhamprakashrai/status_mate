import 'package:flutter/material.dart';

class StatusSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool isSearching;
  final VoidCallback onSearchPressed;
  final VoidCallback onCancelPressed;

  const StatusSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.isSearching,
    required this.onSearchPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isSearching ? 60 : 0,
      child: isSearching
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search statuses...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancelPressed,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
