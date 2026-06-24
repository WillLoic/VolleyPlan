class BlogArticle {
  final String slug;
  final Map<String, String> title;
  final Map<String, String> category;
  final String readTime;
  final String date;
  final Map<String, String> snippet;
  final Map<String, List<String>> content;

  const BlogArticle({
    required this.slug,
    required this.title,
    required this.category,
    required this.readTime,
    required this.date,
    required this.snippet,
    required this.content,
  });

  String getTitle(String langCode) => title[langCode] ?? title['fr'] ?? '';
  String getCategory(String langCode) => category[langCode] ?? category['fr'] ?? '';
  String getSnippet(String langCode) => snippet[langCode] ?? snippet['fr'] ?? '';
  List<String> getContent(String langCode) => content[langCode] ?? content['fr'] ?? [];

  static const List<BlogArticle> articles = [
    BlogArticle(
      slug: 'comment-planifier-une-saison-de-volleyball-reussie',
      title: {
        'fr': 'Comment planifier une saison de volleyball réussie : le guide complet',
        'en': 'How to Plan a Successful Volleyball Season: The Ultimate Guide'
      },
      category: {
        'fr': 'Planification',
        'en': 'Planning'
      },
      readTime: '5 min',
      date: '23 Juin 2026',
      snippet: {
        'fr': 'Découvrez la méthode étape par étape pour structurer vos cycles d\'entraînement, équilibrer votre charge de travail et amener votre équipe au pic de sa forme le jour J.',
        'en': 'Discover the step-by-step method to structure your training cycles, balance your workload, and bring your team to its peak performance when it matters most.'
      },
      content: {
        'fr': [
          'La réussite d\'une saison de volleyball ne repose pas sur le hasard, mais sur une planification rigoureuse. Trop d\'entraîneurs commencent la saison sans fil conducteur, ce qui mène souvent à de la fatigue accumulée, des blessures ou un manque de cohérence tactique lors des matchs cruciaux. Ce guide vous présente les bases de la périodisation appliquées au volley.',
          '### 1. Définir les phases de la saison',
          'Une saison typique se divise en trois grandes périodes : la préparation (ou pré-saison), la compétition, et la transition. Durant la phase de préparation, l\'accent doit être mis sur le développement physique (cardio, force) et les fondamentaux techniques. À l\'approche des premiers matchs, la charge physique diminue pour laisser place à la cohésion tactique et au système de jeu.',
          '### 2. Équilibrer les domaines de jeu',
          'Le volleyball moderne exige un équilibre parfait entre les différents compartiments de jeu : le service, la réception, la passe, l\'attaque, le bloc et la défense. Un bon plan d\'entraînement doit refléter cet équilibre. Il est recommandé de suivre précisément le temps alloué à chaque domaine. Par exemple, si vous passez 80% de votre temps sur l\'attaque et négligez la relation bloc-défense, votre équipe manquera de stabilité en compétition.',
          '### 3. Ajuster selon les retours physiques',
          'Le suivi de la charge de travail est indispensable pour prévenir le surentraînement. Un planning n\'est pas gravé dans le marbre : si vos joueurs montrent des signes de fatigue extrême, sachez alléger les séances de sauts et intensifier le travail de transition ou les retours vidéo. La flexibilité est la clé d\'un coaching moderne et respectueux de la santé des athlètes.',
          '### 4. Simplifier la communication avec le staff',
          'Si vous travaillez avec des assistants ou des préparateurs physiques, la centralisation des plannings est primordiale. Chaque membre du staff doit savoir précisément ce qui a été travaillé la veille pour ajuster son propre module de travail. L\'utilisation d\'un outil comme VolleyPlan simplifie considérablement cette coordination en éliminant les fichiers Excel perdus ou les messages WhatsApp éparpillés.'
        ],
        'en': [
          'A successful volleyball season is never built on luck; it requires rigorous planning. Too many coaches begin their season without a clear roadmap, which often leads to accumulated fatigue, injuries, or a lack of tactical consistency during crucial matches. This guide presents the basics of periodization applied to volleyball.',
          '### 1. Define the Seasons Phases',
          'A typical season is divided into three main periods: preparation (or pre-season), competition, and transition. During the preparation phase, the focus must be on physical development (cardio, strength) and technical fundamentals. As the first matches approach, the physical workload should decrease to prioritize tactical cohesion and system play.',
          '### 2. Balancing Game Domains',
          'Modern volleyball demands a perfect balance between different areas of play: serving, reception, setting, attack, blocking, and defense. A good training plan must reflect this balance. It is highly recommended to track the time allocated to each domain. For instance, if you spend 80% of your time on attack and neglect the block-defense relationship, your team will lack stability in competition.',
          '### 3. Adjust Based on Physical Feedback',
          'Tracking workload is essential to prevent overtraining. A training plan is not written in stone: if your players show signs of extreme fatigue, know how to lighten the jump sessions and focus on transition work or video analysis. Flexibility is key to modern coaching that respects athlete health.',
          '### 4. Simplify Staff Communication',
          'If you work with assistants or physical trainers, centralizing schedules is vital. Every staff member must know exactly what was worked on the day before to adjust their own training modules. Using an app like VolleyPlan simplifies this coordination by eliminating lost Excel files or scattered WhatsApp messages.'
        ]
      }
    ),
    BlogArticle(
      slug: '5-exercices-cles-pour-la-reception-et-la-defense',
      title: {
        'fr': '5 exercices clés pour transformer la réception de votre équipe',
        'en': '5 Key Drills to Transform Your Teams Reception and Defense'
      },
      category: {
        'fr': 'Technique',
        'en': 'Technique'
      },
      readTime: '4 min',
      date: '18 Juin 2026',
      snippet: {
        'fr': 'La réception est le point de départ de toute attaque réussie. Découvrez 5 ateliers simples et efficaces pour stabiliser le premier contact de vos joueurs.',
        'en': 'Reception is the starting point of any successful attack. Discover 5 simple and effective drills to stabilize your players first contact.'
      },
      content: {
        'fr': [
          'En volleyball, on dit souvent que la réception fait le passeur. Sans un bon premier contact, il est impossible de déployer un jeu offensif rapide et varié. Voici cinq exercices conçus pour améliorer la posture, la lecture de trajectoire et la communication de vos réceptionneurs.',
          '### 1. La Poursuite de Trajectoire (sans ballon)',
          'Avant de toucher la balle, le placement est prioritaire. Cet exercice demande aux joueurs de suivre le déplacement d\'un ballon lancé ou frappé par le coach et de venir se positionner parfaitement dessous, en adoptant la posture de réception (plateforme formée, bassin bas, épaules dirigées vers la cible) sans intercepter le ballon. Le but est d\'apprendre à lire la courbe du ballon.',
          '### 2. Le Papillon Continu (drill classique)',
          'Idéal pour le warm-up technique, le système en papillon permet de travailler la relation serveur-réceptionneur-passeur en continu. Les serveurs visent des zones spécifiques, les réceptionneurs orientent la balle vers la cible, et les passeurs attrapent la balle avant de passer au poste de serveur. Cet exercice augmente la répétition et automatise le geste technique de la plateforme.',
          '### 3. La Réception sous Pression Ciblée',
          'Positionnez trois réceptionneurs sur le terrain. Le coach ou des serveurs depuis l\'autre côté ciblent systématiquement un joueur précis (par exemple, le joueur en Poste 5) ou les zones de conflit (entre le Poste 6 et 5). Les joueurs doivent communiquer à haute voix ("J\'ai !" ou "À toi !") avant d\'intervenir. Cet exercice renforce la cohésion et la clarté sous pression.',
          '### 4. Le Drill de Transition Défense-Attaque',
          'Enchaînez une défense difficile en poste 1 ou 5 suivie immédiatement d\'une reconstruction d\'attaque. Le passeur doit s\'adapter à un ballon de défense parfois imprécis pour offrir une solution d\'attaque correcte. Cela habitue l\'équipe à rester lucide et organisée même dans le chaos d\'une transition rapide.',
          '### 5. La Réception en Surcharge Visuelle',
          'Pour développer les réflexes et la vitesse de décision, demandez à vos réceptionneurs de fermer les yeux jusqu\'à ce que le serveur frappe le ballon, ou d\'utiliser des écrans visuels (des joueurs placés devant eux qui se baissent au dernier moment). Cela force le réceptionneur à réagir de manière explosive et à adapter instantanément la structure de ses bras.'
        ],
        'en': [
          'In volleyball, they often say that reception makes the setter. Without a solid first touch, running a fast and diverse offensive system is impossible. Here are five drills designed to improve posture, ball tracking, and communication among your passers.',
          '### 1. Trajectory Tracking (no ball)',
          'Before touching the ball, movement is the priority. This drill requires players to track the movement of a ball tossed or hit by the coach and position themselves perfectly under it, adopting the correct reception posture (formed platform, low hips, shoulders facing the target) without catching it. The goal is learning to read the ball\'s curve.',
          '### 2. The Continuous Butterfly (classic drill)',
          'Ideal for technical warm-ups, the butterfly system allows continuous training of the server-passer-setter relationship. Servers target specific zones, passers direct the ball to the target, and setters catch the ball before rotating to the server spot. This drill maximizes repetitions and builds technical muscle memory.',
          '### 3. Reception Under Target Pressure',
          'Place three passers on the court. Servers or the coach from the opposite side systematically target a specific player (e.g., position 5) or conflict zones (between position 6 and 5). Players must call the ball out loud ("Mine!" or "Yours!") before contacting it. This builds communication and clarity under pressure.',
          '### 4. Defense-to-Attack Transition Drill',
          'Chain a difficult defensive save in position 1 or 5 immediately followed by an attacking play. The setter must adjust to an out-of-system dig to deliver a playable attack. This trains the team to stay focused and organized during chaotic, high-speed transitions.',
          '### 5. Visual Overload Reception',
          'To develop fast reflexes and decision-making speed, have your passers close their eyes until the server hits the ball, or use visual screens (players standing in front who duck at the last moment). This forces the passer to react explosively and align their arms instantly.'
        ]
      }
    ),
    BlogArticle(
      slug: 'le-secret-de-la-collaboration-staff-coach',
      title: {
        'fr': 'Le secret de la collaboration staff-coach : comment bien s\'organiser',
        'en': 'The Secret of Coach-Staff Collaboration: How to Stay Organized'
      },
      category: {
        'fr': 'Organisation',
        'en': 'Management'
      },
      readTime: '3 min',
      date: '12 Juin 2026',
      snippet: {
        'fr': 'Travailler en synergie avec vos adjoints et préparateurs physiques est un booster de performance. Voici comment fluidifier vos échanges.',
        'en': 'Working in synergy with your assistants and physical trainers is a massive performance booster. Here is how to streamline your team management.'
      },
      content: {
        'fr': [
          'Diriger un club de volleyball n\'est pas un sport individuel. Que vous ayez un assistant technique, un préparateur physique ou un kiné, la réussite de l\'équipe dépend de la qualité de votre communication interne. Une mauvaise transmission d\'informations peut ruiner des semaines de préparation ou causer des surcharges physiques inutiles pour vos joueurs.',
          '### 1. La définition des rôles',
          'Le premier pas vers une collaboration fluide est la clarté des rôles. Qui s\'occupe de la préparation physique ? Qui gère les statistiques pendant le match ? Qui prépare les séances spécifiques passeurs ? Lorsque chacun connaît son périmètre, la prise de décision est plus rapide et les conflits d\'autorité disparaissent.',
          '### 2. Le partage en temps réel des séances',
          'Trop souvent, le préparateur physique planifie des séances de musculation intenses le matin même d\'un entraînement technique où le coach a prévu des exercices de sauts intensifs. Le résultat ? Une fatigue accumulée qui nuit à la qualité technique et augmente le risque de blessure. En partageant un planning unique et accessible en direct, le staff peut synchroniser ses cycles pour optimiser la forme des athlètes.',
          '### 3. La centralisation des données des joueurs',
          'Avoir un seul endroit pour noter les absences, les blessures en cours et les retours de forme évite les quiproquos. Plus besoin de chercher dans des conversations WhatsApp interminables si tel joueur a reçu le feu vert médical pour reprendre les sauts. Les informations clés doivent être associées directement au profil du joueur dans votre système de gestion d\'équipe.',
          '### 4. Automatiser le partage de l\'information',
          'Le temps d\'un coach est précieux. Réduire le temps passé à copier-coller des plannings pour les envoyer au staff ou aux joueurs par message est une victoire facile. Adopter une plateforme centralisée permet à vos collaborateurs d\'éditer ou consulter le planning à tout moment, libérant des heures de gestion administrative au profit du travail sur le terrain.'
        ],
        'en': [
          'Leading a volleyball club is not an individual sport. Whether you work with an assistant coach, a fitness trainer, or a physio, the team\'s success depends entirely on the quality of your internal communication. Poor information flow can ruin weeks of work or cause unnecessary physical overload for players.',
          '### 1. Define Clear Roles',
          'The first step toward smooth collaboration is role clarity. Who is in charge of strength and conditioning? Who handles live stats during matches? Who leads positional training for setters? When everyone knows their exact domain, decisions are made faster and friction disappears.',
          '### 2. Real-Time Practice Sharing',
          'All too often, a fitness coach schedules a heavy weightlifting session on the morning of a practice where the head coach planned intense jumping drills. The result? Excessive fatigue that degrades technical quality and spikes injury risks. By sharing a single, live-updating schedule, the staff can synchronize their cycles to maximize athlete performance.',
          '### 3. Centralizing Player Health Data',
          'Having a single source of truth for attendance, active injuries, and recovery progress avoids costly misunderstandings. No more digging through endless chat groups to check if a player is cleared to jump. Key health and roster updates should be logged directly in your team management system.',
          '### 4. Automate Information Flow',
          'A coach\'s time is precious. Minimizing the hours spent copying and pasting schedules to text to your staff or players is an easy win. Moving to a centralized coaching platform allows collaborators to edit or view the training plan at any time, freeing up administrative hours to focus on court work.'
        ]
      }
    )
  ];
}
