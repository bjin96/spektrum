import 'dart:async';

import 'package:spektrum/model/spektrum_user.dart';

import '../socket_connection.dart';
import 'excerpt.dart';
import 'result.dart';
import 'game.dart';

class ContactPageInfo {

  static const String SOCKET_NAMESPACE = 'view_';

  SpektrumUser user;
  List<String> contactList;
  List<String> friendRequestList;
  List<String> pendingFriendRequestList;
  List<String> openGameList;
  List<String> challengeList;
  List<String> challengeSentList;
  List<String> speakerIdList;

  ContactPageInfo(
      {this.user,
        this.contactList,
        this.friendRequestList,
        this.pendingFriendRequestList,
        this.challengeList,
        this.challengeSentList,
        this.openGameList,
        this.speakerIdList});

  static Future<ContactPageInfo> getContactPageInfo(String userId) async {
    final Map<String, dynamic> body = {'userId': userId};
    Map<String, dynamic> json = await SocketConnection.send(SOCKET_NAMESPACE + 'contact_page', body);
    return ContactPageInfo(
      user: SpektrumUser.fromJson(json['user']),
      contactList: List<String>.from(json['contactList']),
      friendRequestList: List<String>.from(json['friendRequestList']),
      pendingFriendRequestList: List<String>.from(json['pendingFriendRequestList']),
      challengeList: List<String>.from(json['challengeList']),
      challengeSentList: List<String>.from(json['challengeSentList']),
      openGameList: List<String>.from(json['openGameList']),
      speakerIdList: List<String>.from(json['speakerIdList']),
    );
  }
}


class PreGamePageInfo {

  static const String SOCKET_NAMESPACE = 'view_';

  SpektrumUser user;
  SpektrumUser opponent;

  Game userGame;
  Game opponentGame;

  PreGamePageInfo(
      {this.user,
        this.opponent,
        this.userGame,
        this.opponentGame});

  static Future<PreGamePageInfo> getPreGamePageInfo(SpektrumUser user, String opponentId) async {
    final Map<String, dynamic> body = {'opponentId': opponentId};
    Map<String, dynamic> json = await SocketConnection.send(SOCKET_NAMESPACE + 'pre_game_page', body);
    return PreGamePageInfo(
      user: user,
      opponent: SpektrumUser.fromJson(json['opponent']),
      userGame: Game.fromJson(json['userGame']),
      opponentGame: Game.fromJson(json['opponentGame']),
    );
  }
}

class GamePageInfo {

  static const String SOCKET_NAMESPACE = 'view_';

  List<Excerpt> excerptList;
  List<Result> resultList;

  GamePageInfo(
      {this.excerptList,
      this.resultList});

  static Future<GamePageInfo> getGamePageInfo(int gameId) async {
    final Map<String, dynamic> body = {'gameId': gameId};
    Map<String, dynamic> json = await SocketConnection.send(SOCKET_NAMESPACE + 'game_page', body);
    final excerptList = List.generate(json['excerptList'].length, (i) {
      return Excerpt(
          speakerFirstName: json['excerptList'][i]['speakerFirstName'],
          speakerLastName: json['excerptList'][i]['speakerLastName'],
          party: json['excerptList'][i]['party'],
          socioCulturalCoordinate: json['excerptList'][i]['socioCulturalCoordinate'],
          socioEconomicCoordinate: json['excerptList'][i]['socioEconomicCoordinate'],
          content: json['excerptList'][i]['content'],
          speechId: json['excerptList'][i]['speechid'],
          fragment: json['excerptList'][i]['fragment'],
          counter: json['excerptList'][i]['counter'],
          topic: json['excerptList'][i]['topic'],
          bio: json['excerptList'][i]['bio'],
          speakerId: json['excerptList'][i]['speakerId']);
    });

    final resultList = List.generate(json['resultList'].length, (i) {
      return Result(
        gameId: json['resultList'][i]['gameId'],
        excerptCounter: json['resultList'][i]['excerptCounter'],
        userId: json['resultList'][i]['userId'],
        socioCulturalCoordinate: json['resultList'][i]['socioCulturalCoordinate'],
        socioEconomicCoordinate: json['resultList'][i]['socioEconomicCoordinate'],
        distance: json['resultList'][i]['distance'],
      );
    });

    return GamePageInfo(
      excerptList: excerptList,
      resultList: resultList,
    );
  }
}