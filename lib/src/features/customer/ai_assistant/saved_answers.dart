/// Local answers used only after the live assistant fails. No live stock,
/// prices, orders or local-season claims are stored here.
String savedAssistantAnswer(String question) {
  final q = question.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  // General food guidance: NIH Vitamin C consumer fact sheet and FDA's
  // Selecting and Serving Produce Safely / Storage and Handling of Tomatoes.
  if (RegExp(r'vitamin\s*c\b').hasMatch(q)) {
    return 'Oranges, grapefruit, kiwi and strawberries provide vitamin C. '
        'Bell peppers and broccoli are useful vegetable sources too. '
        'Choose a variety you enjoy. Check Explore for current availability.';
  }
  if (q.contains('tomato') &&
      RegExp(r'stor|keep|fresh|fridge|refriger').hasMatch(q)) {
    return 'Keep whole, uncut tomatoes in a clean, dry place away from direct sunlight while they ripen. '
        'Wash them under running water before preparing them. '
        'Refrigerate cut tomatoes promptly in a covered container at 4°C or below. '
        'Discard produce that is rotten.';
  }
  if (RegExp(r'season|seasonal').hasMatch(q)) {
    return 'Seasonal vegetables depend on your region, weather and growing conditions. '
        'Ask a local farmer what is being harvested now, then check the app’s product listings. '
        'This saved answer cannot verify today’s season or stock for your location.';
  }
  if (q.contains('spinach')) {
    return 'Spinach is a leafy green that adds variety to meals. '
        'Try it in salads, soups or a quick sauté alongside other vegetables. '
        'Keep it refrigerated and rinse it under running water before preparing it '
        '(follow the package instructions for ready-to-eat leaves). '
        'For nutrition advice specific to a health condition, ask your clinician.';
  }
  if (q.contains('salad')) {
    return 'Try leafy greens, cucumber, tomato, shredded carrot and bell pepper. '
        'Add cooked chickpeas or beans for a more filling salad, then dress with lemon and olive oil. '
        'Rinse fresh vegetables under running water and keep prepared salad refrigerated. '
        'Check Explore for the ingredients currently listed by farmers.';
  }
  if (q.contains('follow') ||
      q.contains('heart') ||
      q.contains('favourite') ||
      q.contains('favorite')) {
    return 'Open a farm and tap Follow to save it to your followed farms; the button changes to Following. '
        'Tap a product’s heart to save that product. Tap again to remove it. '
        'Sign in and connect to the internet so your choices can sync.';
  }
  if (q.contains('password') || q.contains('2fa') || q.contains('email')) {
    return 'Open Profile and the account security settings to change your password or email, '
        'or enable or disable email two-step verification. You will need your current password and an email code. '
        'Follow the verification instructions in the app. Never send passwords or email codes to the assistant.';
  }
  if (q.contains('pickup') || q.contains('order')) {
    return 'Open My orders to see your order’s current status and pickup details. '
        'Use its available booking options to choose a pickup window. '
        'This saved answer cannot check your order or make a booking.';
  }
  return 'I have saved tips about vitamin C foods, storing tomatoes, seasonal produce, spinach and salads, '
      'plus help with following farms, account security and pickup orders. '
      'Ask about one of those topics, or retry your question when the AI service is available. '
      'Saved answers cannot check live prices, stock or account information.';
}
