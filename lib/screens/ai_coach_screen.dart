import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/ai_api_service.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/app_theme.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final AnimationController _shimmerController;
  bool _insightsLoaded = false;
  bool _isChatOpen = false;
  String _muscleBalance = '';
  String _overloadSuggestion = '';

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInsights());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    final workoutProvider = context.read<WorkoutProvider>();
    final userProvider = context.read<UserProvider>();
    final profile = _profileOrFallback(userProvider.user);
    final recentMuscles = workoutProvider.recentMuscles();

    setState(() {
      _insightsLoaded = false;
      _muscleBalance = '';
      _overloadSuggestion = '';
    });

    final results = await Future.wait([
      AiApiService.instance.getMissingMusclesSuggestion(recentMuscles, profile),
      _buildOverloadSuggestion(workoutProvider, profile),
    ]);

    if (!mounted) return;
    setState(() {
      _muscleBalance = results[0];
      _overloadSuggestion = results[1];
      _insightsLoaded = true;
    });
  }

  Future<String> _buildOverloadSuggestion(
      WorkoutProvider workoutProvider, UserProfile profile) async {
    if (workoutProvider.logs.isEmpty) {
      return 'No workout history yet. Complete a session to unlock overload guidance.';
    }

    final mostRecentLog = workoutProvider.logs.first;
    if (mostRecentLog.exercises.isEmpty) {
      return 'No exercise history found in the latest workout.';
    }

    final exercise = mostRecentLog.exercises.first;
    final targetReps = exercise.targetReps;
    final lastWeight = exercise.maxWeight > 0
        ? exercise.maxWeight
        : (exercise.lastWeight ?? 0);

    return AiApiService.instance.getOverloadSuggestion(
      exerciseName: exercise.exerciseName,
      lastWeight: lastWeight,
      lastReps: exercise.loggedSets.isNotEmpty
          ? exercise.loggedSets.last.reps
          : targetReps,
      targetReps: targetReps,
      profile: profile,
    );
  }

  UserProfile _profileOrFallback(UserProfile? profile) {
    if (profile != null) return profile;
    return UserProfile(
      nickname: 'Athlete',
      age: 25,
      weightKg: 75,
      heightCm: 175,
      goal: 'Build Muscle',
      fitnessLevel: 'Beginner',
      availableEquipment: const ['Gym'],
      workoutsPerWeek: 3,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final profile = _profileOrFallback(context.read<UserProvider>().user);
    final userMessage = _ChatMessage(role: 'user', content: text);

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
    });
    _scrollChatToBottom();

    final response = await AiApiService.instance
        .chat(text, profile);
    final aiMessage = _ChatMessage(role: 'assistant', content: response);

    if (!mounted) return;
    setState(() {
      _messages.add(aiMessage);
    });
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
    if (_isChatOpen) {
      _scrollChatToBottom();
    }
  }

  void _closeChat() {
    if (!_isChatOpen) return;
    setState(() {
      _isChatOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = _profileOrFallback(userProvider.user);
    final isLoadingInsights = !_insightsLoaded;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text("AI Coach"),
        backgroundColor: AppTheme.surface,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text(
                    'Smart Insights',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _InsightCard(
                    title: 'Muscle Balance',
                    isLoading: isLoadingInsights,
                    content: _muscleBalance.isEmpty
                        ? 'Analyzing recent muscle coverage...'
                        : _muscleBalance,
                    controller: _shimmerController,
                  ),
                  const SizedBox(height: 16),
                  _InsightCard(
                    title: 'Progressive Overload',
                    isLoading: isLoadingInsights,
                    content: _overloadSuggestion.isEmpty
                        ? 'Reviewing your most recent lift...'
                        : _overloadSuggestion,
                    controller: _shimmerController,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: AnimatedScale(
                scale: _isChatOpen ? 0.95 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: FloatingActionButton.extended(
                  onPressed: _toggleChat,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: Icon(
                      _isChatOpen ? Icons.close : Icons.smart_toy_outlined),
                  label: Text(_isChatOpen ? 'Close AI' : 'AI Coach'),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_isChatOpen,
              child: AnimatedOpacity(
                opacity: _isChatOpen ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeChat,
                  child: Container(
                    color: Colors.black.withOpacity(0.18),
                    child: AnimatedSlide(
                      offset: _isChatOpen ? Offset.zero : const Offset(0, 0.08),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard.withOpacity(0.98),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 24,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.58,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 14, 12, 10),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.chat_bubble_outline,
                                                color: AppTheme.primary,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Chat with Coach',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary),
                                            ),
                                            const Spacer(),
                                            Text(
                                              profile.nickname,
                                              style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12),
                                            ),
                                            IconButton(
                                              tooltip: 'Close chat',
                                              onPressed: _closeChat,
                                              icon: const Icon(Icons.close,
                                                  size: 18,
                                                  color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: ListView.builder(
                                          controller: _chatScrollController,
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _messages.isEmpty
                                              ? 1
                                              : _messages.length,
                                          itemBuilder: (context, index) {
                                            if (_messages.isEmpty) {
                                              return const Text(
                                                'Ask about recovery, overload, form, or workout planning.',
                                                style: TextStyle(
                                                    color:
                                                        AppTheme.textSecondary),
                                              );
                                            }

                                            final message = _messages[index];
                                            return _ChatBubble(message: message);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _messageController,
                                                textInputAction:
                                                    TextInputAction.send,
                                                onSubmitted: (_) =>
                                                    _sendMessage(),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      'Message your coach...',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            SizedBox(
                                              height: 52,
                                              width: 52,
                                              child: ElevatedButton(
                                                onPressed: _sendMessage,
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14)),
                                                ),
                                                child: const Icon(Icons.send),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;

  const _ChatMessage({required this.role, required this.content});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : AppTheme.textPrimary,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isLoading;
  final AnimationController controller;

  const _InsightCard({
    required this.title,
    required this.content,
    required this.isLoading,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (isLoading)
            _ShimmerBlock(controller: controller)
          else
            Text(content,
                style: const TextStyle(
                    color: AppTheme.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final AnimationController controller;

  const _ShimmerBlock({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final slide = controller.value * 2 - 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 10),
                  Container(
                      height: 14,
                      width: 220,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 10),
                  Container(
                      height: 14,
                      width: 160,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999))),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment(slide, 0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
