import '../common/notifications/notifications.dart';
import '../common/shared/forms/phone_validation.dart';

import 'dart:async';

import '../authentication/demo/guest_sign_in.dart';

import '../common/shared/theme_reveal.dart';
import 'widgets/customer_style.dart';

import 'ai_assistant/assistant_robot.dart';
import '../common/location/location_picker.dart';

import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../common/shared/components.dart';
import '../common/data/models.dart';
import 'checkout/confirmation.dart';
export 'checkout/confirmation.dart' show ConfirmationScreen;
import '../common/profile/profile.dart';
import '../common/data/store.dart';
import '../common/shared/theme.dart';

part 'farmers/follow_action.dart';
part 'cart/basket_action.dart';
part 'home/home_screen.dart';
part 'search_filter/explore_screen.dart';
part 'product_details/product_screen.dart';
part 'farmers/farm_screen.dart';
part 'farmers/farmer_feedback_screen.dart';
part 'wishlist/wishlist_screen.dart';
part 'cart/cart_screen.dart';
part 'checkout/checkout_screen.dart';
part 'farmers/all_farms_screen.dart';
