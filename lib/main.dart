import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('appData');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mes Points Bonnes Actions',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: HomeScreen(),
    );
  }
}

// Palette de couleurs
const Color primaryColor = Color(0xFF4D96FF);
const Color secondaryColor = Color(0xFFFFD93D);
const Color successColor = Color(0xFF6BCB77);
const Color dangerColor = Color(0xFFFF6F59);

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor.withOpacity(0.2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mes Points Bonnes Actions',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text('Mode Enfant', style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChildListScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text('Mode Parent', style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PinScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PinScreen extends StatefulWidget {
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entrer le code PIN')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: pinController,
              decoration: InputDecoration(labelText: 'Code PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Valider'),
              onPressed: () {
                if (pinController.text == '1234') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ParentScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Code incorrect'),
                      backgroundColor: dangerColor,
                    ),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

class ParentScreen extends StatefulWidget {
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  Box box = Hive.box('appData');
  List children = [];

  final List<Color> avatarColors = [
    Color(0xFFFFD93D),
    Color(0xFF4D96FF),
    Color(0xFF6BCB77),
    Color(0xFFFF6F59),
  ];

  final List<String> avatarEmojis = [
    '🐶', '🐱', '🐰', '🦊', '🦁', '🐼', '🐧', '🐸', '🦉', '🐯'
  ];

  @override
  void initState() {
    super.initState();
    loadChildren();
  }

  void loadChildren() {
    setState(() {
      children = box.get('children', defaultValue: []);
    });
  }

  void addChild(String name, String avatar) {
    children.add({
      'name': name,
      'avatar': avatar,
      'color': avatarColors[children.length % avatarColors.length].value,
      'points': 0,
      'punishments': [],
      'goodActions': []
    });
    box.put('children', children);
    loadChildren();
  }

  void removeChild(int index) {
    children.removeAt(index);
    box.put('children', children);
    loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mode Parent')),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(child['color']),
                child: Text(
                  child['avatar'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
              title: Text(child['name']),
              subtitle: Text('Punitions : ${child['punishments'].length}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: dangerColor),
                onPressed: () => removeChild(index),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PunishmentScreen(
                      childIndex: index,
                      childData: child,
                      onUpdate: loadChildren,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: successColor,
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) {
              String name = '';
              String avatar = avatarEmojis.first;
              return AlertDialog(
                title: Text('Nouvel enfant'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Prénom'),
                      onChanged: (val) => name = val,
                    ),
                    DropdownButton<String>(
                      value: avatar,
                      onChanged: (val) {
                        avatar = val!;
                        setState(() {});
                      },
                      items: avatarEmojis
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e, style: TextStyle(fontSize: 24)),
                              ))
                          .toList(),
                    )
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (name.isNotEmpty) {
                        addChild(name, avatar);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Ajouter'),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class PunishmentScreen extends StatefulWidget {
  final int childIndex;
  final Map childData;
  final VoidCallback onUpdate;

  PunishmentScreen({
    required this.childIndex,
    required this.childData,
    required this.onUpdate,
  });

  @override
  State<PunishmentScreen> createState() => _PunishmentScreenState();
}

class _PunishmentScreenState extends State<PunishmentScreen> {
  Box box = Hive.box('appData');
  late List punishments;
  late List goodActions;

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    punishments = widget.childData['punishments'];
    goodActions = widget.childData['goodActions'];
  }

  void saveData() {
    List children = box.get('children', defaultValue: []);
    children[widget.childIndex] = widget.childData;
    box.put('children', children);
    widget.onUpdate();
    setState(() {});
  }

  void addPunishment(String reason, int neededPoints) {
    widget.childData['punishments'].add({
      'reason': reason,
      'neededPoints': neededPoints,
      'currentPoints': 0
    });
    saveData();
  }

  void addPoints(int punishmentIndex, int points) async {
    var punishment = widget.childData['punishments'][punishmentIndex];
    punishment['currentPoints'] += points;

    if (punishment['currentPoints'] >= punishment['neededPoints']) {
      widget.childData['punishments'].removeAt(punishmentIndex);
      saveData();
      // Play victory sound if available
      if (victorySoundBase64.isNotEmpty) {
        try {
          await player.play(BytesSource(base64Decode(victorySoundBase64)));
        } catch (e) {
          // ignore errors
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CongratsScreen(),
        ),
      );
    } else {
      saveData();
    }
  }

  void addGoodAction(String label, int points) {
    widget.childData['goodActions'].add({
      'label': label,
      'points': points,
    });
    saveData();
  }

  void showGoodActionsDialog(int punishmentIndex) {
    String actionLabel = '';
    int actionPoints = 1;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Attribuer une bonne action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nom de l\'action'),
              onChanged: (val) => actionLabel = val,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Points attribués'),
              keyboardType: TextInputType.number,
              onChanged: (val) =>
                  actionPoints = int.tryParse(val) ?? 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (actionLabel.isNotEmpty) {
                addGoodAction(actionLabel, actionPoints);
                addPoints(punishmentIndex, actionPoints);
                Navigator.pop(context);
              }
            },
            child: Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Punitions de ${widget.childData['name']}')),
      body: ListView.builder(
        itemCount: punishments.length,
        itemBuilder: (context, index) {
          final p = punishments[index];
          double progress =
              p['neededPoints'] == 0 ? 1.0 : p['currentPoints'] / p['neededPoints'];
          return Card(
            child: ListTile(
              title: Text(p['reason']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress),
                  Text(
                      '${p['currentPoints']} / ${p['neededPoints']} points'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.add, color: successColor),
                onPressed: () => showGoodActionsDialog(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(Icons.add_task),
        onPressed: () {
          String reason = '';
          int neededPoints = 5;

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Nouvelle punition'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Raison'),
                    onChanged: (val) => reason = val,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Points nécessaires'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) =>
                        neededPoints = int.tryParse(val) ?? 5,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (reason.isNotEmpty) {
                      addPunishment(reason, neededPoints);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Ajouter'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CongratsScreen extends StatefulWidget {
  @override
  State<CongratsScreen> createState() => _CongratsScreenState();
}

class _CongratsScreenState extends State<CongratsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: successColor.withOpacity(0.1),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎉 Bravo ! 🎉',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Punition terminée !',
                  style: TextStyle(fontSize: 24, color: primaryColor),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Retour'),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [primaryColor, secondaryColor, successColor, dangerColor],
            ),
          ),
        ],
      ),
    );
  }
}

class ChildListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Box box = Hive.box('appData');
    List children = box.get('children', defaultValue: []);
    return Scaffold(
      appBar: AppBar(title: Text('Choisir un enfant')),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(child['color']),
                child: Text(
                  child['avatar'],
                  style: TextStyle(fontSize: 24),
                ),
              ),
              title: Text(child['name']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildScreen(child: child),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChildScreen extends StatelessWidget {
  final Map child;
  ChildScreen({required this.child});

  @override
  Widget build(BuildContext context) {
    List punishments = child['punishments'];
    return Scaffold(
      appBar: AppBar(title: Text('Bonjour ${child['name']}')),
      body: punishments.isEmpty
          ? Center(
              child: Text(
                'Aucune punition en cours 🎉',
                style: TextStyle(fontSize: 22, color: successColor),
              ),
            )
          : ListView.builder(
              itemCount: punishments.length,
              itemBuilder: (context, index) {
                final p = punishments[index];
                double progress = p['neededPoints'] == 0
                    ? 1.0
                    : p['currentPoints'] / p['neededPoints'];
                return Card(
                  child: ListTile(
                    title: Text(p['reason']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: progress),
                        Text(
                            '${p['currentPoints']} / ${p['neededPoints']} points'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Son de victoire encodé en Base64 (laisser vide pour désactiver le son)
const String victorySoundBase64 = '';
