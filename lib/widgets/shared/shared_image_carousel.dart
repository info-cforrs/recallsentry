import 'package:flutter/material.dart';

class SharedImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final bool showIndicators;
  final double height;
  final double width;
  final double borderRadius;
  const SharedImageCarousel({
    required this.imageUrls,
    this.showIndicators = false,
    this.height = 240,
    this.width = 240,
    this.borderRadius = 24,
    super.key,
  });

  @override
  State<SharedImageCarousel> createState() => _SharedImageCarouselState();
}

class _SharedImageCarouselState extends State<SharedImageCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.imageUrls;
    if (imageUrls.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.grey[400],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _FullScreenImageView(imageUrl: url),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (imageUrls.length > 1)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 36),
                        color: Colors.black,
                        onPressed: _currentPage > 0
                            ? () {
                                _controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        tooltip: 'Back',
                      ),
                    ),
                  ),
                ),
              if (imageUrls.length > 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 36),
                        color: Colors.black,
                        onPressed: _currentPage < imageUrls.length - 1
                            ? () {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        tooltip: 'Next',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showIndicators && imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
