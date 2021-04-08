import 'package:flutter/material.dart';
import 'package:twake/pages/feed/channels.dart';
import 'package:twake/pages/feed/directs.dart';

class Feed extends StatefulWidget {
  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<Feed> {
  TabController _controller;
  final _tabs = [Channels(), Directs()];
  var _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    print('Channels tab init');

    _controller = TabController(length: 2, vsync: this);

    _controller.addListener(() {
      setState(() {
        _selectedTab = _controller.index;
      });
      print("Selected tab: " + _controller.index.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      primary: false,
      appBar: AppBar(
        toolbarHeight: 150.0,
        bottom: TabBar(
          controller: _controller,
          indicatorPadding: EdgeInsets.symmetric(horizontal: 15.0),
          indicatorColor: Color(0xff004dff),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            color: Color(0xff8e8e93),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Tab(
                text: 'Channels',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Tab(
                text: 'Direct chats',
              ),
            ),
          ],
        ),
        title: Container(
          width: MediaQuery.of(context).size.width,
          // height: 40,
          child: Text('Channels'),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _controller,
          children: _tabs,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
