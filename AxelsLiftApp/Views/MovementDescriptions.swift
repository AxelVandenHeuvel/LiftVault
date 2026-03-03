import Foundation

struct MovementDescriptions {
    /// Returns a brief 1-2 sentence description for the given movement name.
    static func description(for name: String) -> String {
        descriptions[name]
            ?? "A strength training exercise. Maintain proper form throughout the movement."
    }

    private static let descriptions: [String: String] = [
        // MARK: - Chest (22)
        "Barbell Bench Press":
            "A foundational chest exercise pressing a barbell from chest level to lockout while lying flat. Targets the pectorals, front delts, and triceps — drive your feet into the floor and keep shoulder blades retracted.",
        "Incline Barbell Bench Press":
            "A barbell press on an incline bench (30-45 degrees) emphasizing the upper chest and front delts. Lower the bar to your upper chest and press evenly.",
        "Decline Barbell Bench Press":
            "A barbell press on a decline bench that shifts emphasis to the lower chest. Keep your back flat on the pad and control the bar path.",
        "Dumbbell Bench Press":
            "A flat bench press using dumbbells, allowing a greater range of motion for the chest. Keep the dumbbells in line with your mid-chest and press evenly.",
        "Incline Dumbbell Bench Press":
            "An incline press with dumbbells targeting the upper chest and front delts. Press the weights up and slightly inward without clanking them together.",
        "Decline Dumbbell Bench Press":
            "A decline press with dumbbells emphasizing the lower pectorals. Control the descent and press through the chest, not the shoulders.",
        "Dumbbell Flyes":
            "An isolation exercise where you open your arms wide on a flat bench to stretch and contract the chest. Keep a slight bend in the elbows throughout.",
        "Incline Dumbbell Flyes":
            "Dumbbell flyes performed on an incline bench to target the upper chest. Lower the weights in a wide arc until you feel a stretch, then squeeze back up.",
        "Cable Flyes":
            "A chest isolation movement using cables set at mid-height for constant tension. Bring your hands together in a hugging motion, squeezing the pecs at the center.",
        "Low Cable Flyes":
            "Cable flyes with pulleys set low, sweeping the handles upward to target the upper chest. Maintain a slight elbow bend and control the arc.",
        "High Cable Flyes":
            "Cable flyes with pulleys set high, pulling the handles downward to emphasize the lower chest. Lean slightly forward and squeeze at the bottom.",
        "Push-Ups":
            "A bodyweight pressing movement that targets the chest, shoulders, and triceps. Keep your body in a straight line and lower until your chest nearly touches the floor.",
        "Diamond Push-Ups":
            "Push-ups with hands close together forming a diamond shape, shifting emphasis to the inner chest and triceps. Keep elbows tucked and core tight.",
        "Wide Push-Ups":
            "Push-ups with a wider hand placement to increase the stretch on the chest. Lower with control and avoid flaring the elbows excessively.",
        "Decline Push-Ups":
            "Push-ups with feet elevated on a bench, increasing the load on the upper chest and shoulders. Maintain a rigid core throughout.",
        "Chest Dips":
            "Dips performed with a forward lean to target the chest over the triceps. Lower until you feel a stretch in the pecs, then press back up.",
        "Machine Chest Press":
            "A machine-based pressing movement that isolates the chest with a fixed path. Focus on squeezing the pecs at full extension.",
        "Incline Machine Press":
            "A machine press on an incline angle targeting the upper chest. Press smoothly and avoid locking out aggressively.",
        "Pec Deck":
            "A machine fly that isolates the pectorals through a fixed arc. Squeeze the pads together at the front and control the return.",
        "Landmine Press":
            "A single-arm or double-arm press using a barbell anchored in a landmine. Targets the upper chest and shoulders with a natural arc.",
        "Svend Press":
            "A standing chest squeeze performed by pressing plates together at chest height and extending the arms. Focus on constant pec contraction.",
        "Floor Press":
            "A bench press variation lying on the floor, limiting range of motion to reduce shoulder stress. Targets the chest and triceps from a dead stop.",

        // MARK: - Back (22)
        "Barbell Row":
            "A compound pull where you hinge forward and row a barbell to your lower chest. Targets the lats, rhomboids, and rear delts — keep your back flat.",
        "Dumbbell Row":
            "A single-arm row braced on a bench, targeting the lats and mid-back. Pull the dumbbell to your hip and squeeze the shoulder blade back.",
        "Pendlay Row":
            "A strict barbell row starting from the floor each rep with a flat back. Builds explosive back strength — pull to the lower chest and reset.",
        "Pull-Ups":
            "A bodyweight vertical pull with an overhand grip, targeting the lats and upper back. Pull until your chin clears the bar and lower with control.",
        "Chin-Ups":
            "A vertical pull with an underhand grip, emphasizing the biceps along with the lats. Keep your core tight and pull your chest toward the bar.",
        "Neutral Grip Pull-Ups":
            "Pull-ups using parallel handles for a neutral wrist position, easier on the shoulders. Targets the lats and biceps evenly.",
        "Lat Pulldown":
            "A cable machine pull bringing the bar down to your upper chest to target the lats. Lean back slightly and drive the elbows down.",
        "Close-Grip Lat Pulldown":
            "A lat pulldown with a narrow handle, emphasizing the lower lats and biceps. Pull the handle to your chest and squeeze.",
        "Wide-Grip Lat Pulldown":
            "A lat pulldown with a wide overhand grip to target the outer lats. Pull to your collarbone and control the negative.",
        "Seated Cable Row":
            "A horizontal cable pull targeting the mid-back and lats. Sit tall, pull the handle to your stomach, and squeeze your shoulder blades together.",
        "T-Bar Row":
            "A rowing movement using a T-bar or landmine attachment for thick mid-back development. Keep your chest up and row to your torso.",
        "Face Pulls":
            "A cable pull to face height using a rope, targeting the rear delts and rotator cuff. Pull the rope apart as it reaches your face.",
        "Straight-Arm Pulldown":
            "A cable isolation exercise for the lats performed with straight arms. Push the bar down in an arc from shoulder height to your thighs.",
        "Meadows Row":
            "A single-arm landmine row developed by John Meadows, targeting the lats with a unique angle. Stagger your stance and pull to your hip.",
        "Chest-Supported Row":
            "A row performed lying face-down on an incline bench, removing momentum to isolate the back. Pull the weights to your ribcage.",
        "Inverted Row":
            "A bodyweight row hanging under a bar, targeting the mid-back and lats. Keep your body straight and pull your chest to the bar.",
        "Cable Pullover":
            "A lat isolation movement using a cable, sweeping the bar overhead to your hips. Keep your arms mostly straight and feel the lats stretch and contract.",
        "Single-Arm Cable Row":
            "A unilateral cable row allowing extra rotation and range of motion for the lats. Pull to your hip and rotate slightly.",
        "Rack Pull":
            "A partial deadlift from knee height in a rack, targeting the upper back and traps. Drive your hips forward and lock out at the top.",
        "Seal Row":
            "A barbell or dumbbell row performed lying face-down on a high bench, eliminating all momentum. Pull to your ribcage for pure back isolation.",
        "Kroc Row":
            "A high-rep, heavy single-arm dumbbell row emphasizing grip and back endurance. Use controlled body English and pull hard to the hip.",
        "Machine Row":
            "A machine-based row providing a fixed path to isolate the mid-back. Squeeze your shoulder blades at peak contraction.",

        // MARK: - Shoulders (22)
        "Overhead Press":
            "A standing barbell press from shoulders to overhead, targeting the deltoids and triceps. Brace your core and press straight up past your face.",
        "Dumbbell Shoulder Press":
            "A seated or standing press with dumbbells targeting all three delt heads. Press up and slightly inward without arching your back.",
        "Arnold Press":
            "A dumbbell press with a rotation — start palms facing you and rotate to palms forward as you press. Hits all deltoid heads.",
        "Lateral Raises":
            "An isolation lift raising dumbbells out to your sides to target the lateral delts. Lead with your elbows and stop at shoulder height.",
        "Cable Lateral Raises":
            "Lateral raises using a low cable for constant tension on the side delts. Control the movement and avoid swinging.",
        "Front Raises":
            "An isolation exercise raising a dumbbell or plate in front of you to target the front delts. Lift to shoulder height and lower slowly.",
        "Reverse Flyes":
            "A bent-over or machine fly targeting the rear delts and upper back. Squeeze your shoulder blades together at the top.",
        "Upright Row":
            "A barbell or dumbbell pull from waist to chin level, targeting the traps and lateral delts. Keep the bar close to your body and elbows high.",
        "Machine Shoulder Press":
            "A machine-based overhead press isolating the deltoids with a fixed path. Press smoothly and avoid locking out the elbows aggressively.",
        "Behind-the-Neck Press":
            "An overhead press lowering the bar behind the head to emphasize the rear and lateral delts. Requires good shoulder mobility — use moderate weight.",
        "Dumbbell Shrug":
            "A trap isolation exercise shrugging dumbbells straight up toward your ears. Hold the top briefly and lower with control.",
        "Barbell Shrug":
            "A barbell trap shrug lifting the shoulders straight up. Keep your arms straight and avoid rolling the shoulders.",
        "Lu Raises":
            "A lateral raise variation popularized by Lu Xiaojun — raise with a slight forward angle hitting both lateral and front delts. Use light weight with strict form.",
        "Plate Front Raise":
            "A front raise using a weight plate, targeting the front delts and upper chest. Hold the plate at 9 and 3, raise to eye level.",
        "Cable Face Pull":
            "A cable pull to face height targeting rear delts and external rotators. Set the cable high, pull the rope toward your forehead, and spread it apart.",
        "Seated Lateral Raises":
            "Lateral raises performed seated to eliminate momentum. Raise the dumbbells to shoulder height and lower under control.",
        "Landmine Lateral Raise":
            "A lateral raise using a landmine bar for a unique resistance curve on the side delts. Grip the end of the bar and raise laterally.",
        "Machine Lateral Raise":
            "A machine-based lateral raise isolating the side delts with a fixed path. Press outward and control the return.",
        "Incline Y-Raises":
            "A prone incline bench raise where arms move into a Y shape, targeting the lower traps and rear delts. Use light weights and squeeze at the top.",
        "Bus Drivers":
            "A front raise hold where you rotate a plate side to side like steering a bus. Targets the front delts and rotator cuff with time under tension.",
        "Band Pull-Aparts":
            "A resistance band exercise pulling the band apart at chest height to target rear delts and upper back. Keep arms straight and squeeze your shoulder blades.",
        "Bradford Press":
            "An overhead press alternating the bar in front and behind the head without locking out, keeping constant tension on the delts. Use light to moderate weight.",

        // MARK: - Legs (28)
        "Barbell Squat":
            "The king of leg exercises — a barbell back squat targeting quads, glutes, and hamstrings. Sit back and down, keeping your chest up and knees tracking over toes.",
        "Front Squat":
            "A barbell squat with the bar racked on the front delts, emphasizing the quads and core. Keep your elbows high and torso upright.",
        "Goblet Squat":
            "A squat holding a dumbbell or kettlebell at chest height, great for learning squat mechanics. Sit between your knees and keep your torso tall.",
        "Hack Squat":
            "A machine squat with back support targeting the quads with less spinal load. Press through your feet and control the descent.",
        "Leg Press":
            "A machine press targeting quads, glutes, and hamstrings. Place your feet shoulder-width on the platform and press without locking your knees.",
        "Single-Leg Leg Press":
            "A unilateral leg press to address imbalances and target each leg independently. Press through the heel and control the negative.",
        "Romanian Deadlift":
            "A hip-hinge movement with a barbell that targets the hamstrings and glutes. Keep a slight knee bend and push your hips back until you feel a stretch.",
        "Single-Leg Romanian Deadlift":
            "A unilateral RDL for balance and hamstring isolation. Hinge at the hip while extending one leg behind you, keeping your back flat.",
        "Bulgarian Split Squat":
            "A single-leg squat with the rear foot elevated on a bench, targeting quads and glutes. Drop your back knee toward the floor and drive up through your front heel.",
        "Lunges":
            "A stepping movement targeting quads, glutes, and hamstrings. Step forward, lower your back knee toward the floor, and push back to standing.",
        "Walking Lunges":
            "Continuous forward lunges that challenge balance while targeting the quads and glutes. Keep your torso upright and take controlled steps.",
        "Reverse Lunges":
            "A lunge stepping backward, which is easier on the knees and emphasizes the glutes. Step back, lower, and drive through the front foot.",
        "Curtsy Lunges":
            "A lunge where you step one foot behind and across the other, targeting the glute medius. Keep your hips square and torso upright.",
        "Leg Extension":
            "A machine isolation exercise for the quadriceps. Extend your legs fully and squeeze at the top, then lower with control.",
        "Leg Curl":
            "A machine isolation exercise for the hamstrings performed lying or standing. Curl the pad toward your glutes and squeeze at peak contraction.",
        "Seated Leg Curl":
            "A hamstring curl performed seated on a machine. Press the pad down with your calves and control the return.",
        "Nordic Hamstring Curl":
            "An advanced bodyweight hamstring exercise where you lower yourself from a kneeling position. Resist the descent as slowly as possible.",
        "Hip Thrust":
            "A glute-focused movement driving a barbell upward from a bench-supported position. Squeeze your glutes at the top and avoid hyperextending your back.",
        "Single-Leg Hip Thrust":
            "A unilateral hip thrust isolating each glute individually. Drive through one heel and keep your hips level at the top.",
        "Glute Bridge":
            "A floor-based glute exercise driving your hips up with feet flat on the ground. Squeeze the glutes at the top and hold briefly.",
        "Calf Raises":
            "A standing raise onto your toes targeting the gastrocnemius. Rise as high as possible and lower until you feel a full stretch.",
        "Seated Calf Raises":
            "A calf raise performed seated, targeting the soleus muscle. Press through the balls of your feet and hold the top position.",
        "Donkey Calf Raises":
            "A calf raise with a forward hip hinge, intensifying the stretch on the gastrocnemius. Rise onto your toes and control the negative.",
        "Smith Machine Squat":
            "A squat performed in a Smith machine providing a fixed bar path. Good for isolating the quads — adjust foot placement forward as needed.",
        "Belt Squat":
            "A squat using a belt-loaded machine or attachment, removing spinal load while targeting quads and glutes. Sit back and drive up through your heels.",
        "Step-Ups":
            "A unilateral exercise stepping onto a box or bench, targeting quads and glutes. Drive through the top foot and avoid pushing off the floor foot.",
        "Sissy Squat":
            "A quad-dominant squat leaning backward while rising on your toes. Lower slowly and push through your quads to return up.",
        "Box Squat":
            "A squat to a box that teaches proper depth and builds explosive strength. Sit back onto the box, pause, then drive up.",

        // MARK: - Arms (26)
        "Barbell Curl":
            "A standing bicep curl using a straight barbell. Keep your elbows pinned at your sides and curl the bar to shoulder height.",
        "Dumbbell Curl":
            "A standing or seated curl with dumbbells targeting the biceps. Supinate your wrists as you curl and avoid swinging.",
        "Hammer Curl":
            "A curl with a neutral (palms facing) grip, targeting the brachialis and brachioradialis along with the biceps. Keep elbows stationary.",
        "Preacher Curl":
            "A bicep curl performed over a preacher bench to eliminate momentum. Lower fully and curl to peak contraction.",
        "Cable Curl":
            "A bicep curl using a low cable for constant tension through the full range of motion. Squeeze at the top and lower slowly.",
        "Incline Dumbbell Curl":
            "A curl performed on an incline bench, stretching the long head of the biceps. Let your arms hang straight and curl without moving your elbows.",
        "Concentration Curl":
            "A seated single-arm curl with your elbow braced against your inner thigh. Isolates the biceps with strict form — no swinging.",
        "EZ-Bar Curl":
            "A bicep curl using an EZ-bar which reduces wrist strain with its angled grip. Curl with control and squeeze at the top.",
        "Spider Curl":
            "A curl performed face-down on an incline bench, keeping constant tension on the biceps. Let your arms hang straight and curl to peak contraction.",
        "Reverse Curl":
            "A curl with an overhand grip targeting the brachioradialis and forearm extensors. Keep your wrists straight and elbows locked in place.",
        "Zottman Curl":
            "A curl that combines a supinated curl up and a pronated lower, targeting both the biceps and forearms. Rotate at the top and lower slowly.",
        "Cross-Body Hammer Curl":
            "A hammer curl where you curl the dumbbell across your body toward the opposite shoulder. Emphasizes the brachialis and long head of the biceps.",
        "21s Curl":
            "A bicep curl set broken into three 7-rep segments: lower half, upper half, then full range. Keeps the biceps under constant tension.",
        "Tricep Pushdown":
            "A cable isolation exercise pressing a bar down to target the triceps. Keep your elbows tight to your sides and extend fully.",
        "Rope Tricep Pushdown":
            "A tricep pushdown using a rope attachment, allowing you to spread the ends apart at the bottom for extra contraction. Keep elbows stationary.",
        "Skull Crushers":
            "A lying tricep extension lowering a bar toward your forehead, targeting all three tricep heads. Keep your upper arms vertical and extend from the elbows.",
        "Overhead Tricep Extension":
            "A tricep extension pressing a dumbbell or bar overhead, emphasizing the long head. Keep your elbows close to your head and extend fully.",
        "Cable Overhead Tricep Extension":
            "An overhead tricep extension using a cable for constant tension. Face away from the machine and extend the rope overhead.",
        "Close-Grip Bench Press":
            "A bench press with a narrow grip (hands inside shoulder width) shifting emphasis to the triceps. Keep elbows tucked and press to lockout.",
        "Tricep Dips":
            "Dips performed with an upright torso to emphasize the triceps over the chest. Lower until your elbows hit 90 degrees and press up.",
        "Tricep Kickback":
            "A bent-over dumbbell extension targeting the triceps. Hinge forward, pin your elbow, and extend the weight behind you fully.",
        "JM Press":
            "A hybrid between a close-grip bench press and skull crusher, targeting the triceps with heavy loads. Lower the bar toward your chin and press back up.",
        "Tate Press":
            "A dumbbell tricep extension where you lower the weights inward toward your chest, then press up. Keeps constant tension on the triceps.",
        "Wrist Curl":
            "A forearm flexor exercise curling a barbell or dumbbells with an underhand grip while seated. Move only at the wrists.",
        "Reverse Wrist Curl":
            "A forearm extensor exercise curling with an overhand grip. Rest your forearms on your thighs and extend the wrists upward.",
        "Forearm Roller":
            "A forearm exercise rolling a weighted cord up and down using a wrist roller device. Alternate rolling forward and backward for flexor and extensor work.",

        // MARK: - Compound (16)
        "Deadlift":
            "A full-body pull lifting a barbell from the floor to hip height, targeting the posterior chain. Drive through your heels, keep your back flat, and lock out at the top.",
        "Sumo Deadlift":
            "A wide-stance deadlift with hands inside the knees, emphasizing the quads and adductors. Push the floor apart with your feet and keep your chest up.",
        "Trap Bar Deadlift":
            "A deadlift using a hex/trap bar, allowing a more neutral grip and upright torso. Great for overall strength with reduced lower-back stress.",
        "Power Clean":
            "An explosive Olympic lift pulling the barbell from the floor to the front rack position. Drive with your legs and shrug the bar up before catching it.",
        "Clean and Press":
            "A combination of a power clean into an overhead press, working the full body. Clean the bar to your shoulders, then press overhead.",
        "Hang Clean":
            "A clean variation starting from a hanging position above the knees, focusing on explosive hip extension. Pull and catch in a front squat position.",
        "Snatch":
            "An Olympic lift taking the barbell from the floor to overhead in one motion. Requires explosive hip drive and overhead stability.",
        "Muscle Snatch":
            "A snatch variation without dropping under the bar, pulling it directly overhead with muscle. Great for building overhead strength and technique.",
        "Thruster":
            "A front squat into an overhead press performed as one fluid movement. Drive out of the squat and use the momentum to press the bar overhead.",
        "Push Press":
            "An overhead press using a slight leg dip to generate momentum. Dip your knees, drive up, and press the bar to lockout.",
        "Farmer's Walk":
            "A loaded carry holding heavy dumbbells or handles at your sides while walking. Targets grip, traps, core, and overall stability — stand tall and walk briskly.",
        "Turkish Get-Up":
            "A full-body movement transitioning from lying to standing while holding a weight overhead. Builds shoulder stability, core strength, and coordination.",
        "Kettlebell Swing":
            "An explosive hip-hinge movement swinging a kettlebell to chest or overhead height. Drive with your hips and squeeze your glutes at the top.",
        "Man Maker":
            "A complex combining a dumbbell burpee, row, and press into one brutal sequence. Maintain control through each phase and keep your core braced.",
        "Devil Press":
            "A dumbbell burpee into a double snatch, combining conditioning with overhead power. Swing the dumbbells overhead in one explosive motion from the floor.",
        "Sled Push":
            "A conditioning exercise pushing a weighted sled across the floor. Stay low, drive with your legs, and keep your core braced throughout.",

        // MARK: - Core (18)
        "Plank":
            "An isometric core hold in a push-up position, targeting the rectus abdominis and deep stabilizers. Keep your body in a straight line and squeeze your glutes.",
        "Side Plank":
            "A lateral isometric hold on one forearm, targeting the obliques and lateral core. Stack your feet and keep your hips elevated.",
        "Hanging Leg Raise":
            "A core exercise hanging from a bar and raising straight legs to parallel or above. Control the swing and focus on curling your pelvis up.",
        "Hanging Knee Raise":
            "A hanging core exercise raising bent knees toward your chest. Keep the movement controlled and avoid swinging.",
        "Cable Crunch":
            "A kneeling crunch using a cable rope for weighted ab training. Curl your torso downward, bringing your elbows toward your knees.",
        "Ab Wheel Rollout":
            "An advanced core exercise rolling an ab wheel forward and back from a kneeling position. Extend as far as you can control while keeping your back from sagging.",
        "Russian Twist":
            "A seated rotational core exercise twisting side to side with a weight. Lean back slightly, lift your feet, and rotate through your torso.",
        "Bicycle Crunch":
            "A dynamic crunch alternating elbow to opposite knee, targeting the obliques and rectus abdominis. Move with control rather than speed.",
        "Dragon Flag":
            "An advanced core exercise made famous by Bruce Lee — lower your rigid body from a bench using only your core. Keep your body straight as a plank.",
        "Pallof Press":
            "An anti-rotation core exercise pressing a cable or band straight out from your chest. Resist the pull and keep your hips square.",
        "Decline Sit-Up":
            "A sit-up performed on a decline bench to increase resistance on the abs. Cross your arms or hold a weight and curl up with control.",
        "Dead Bug":
            "A supine core stability exercise extending opposite arm and leg while keeping your lower back pressed into the floor. Move slowly and with control.",
        "Bird Dog":
            "A quadruped core exercise extending opposite arm and leg simultaneously. Keep your hips level and core braced throughout.",
        "Mountain Climbers":
            "A dynamic plank-based exercise driving alternating knees toward your chest. Keep your hips low and move at a controlled pace.",
        "Woodchops":
            "A rotational core exercise pulling a cable or weight diagonally across your body. Rotate through your torso, not your arms.",
        "Copenhagen Plank":
            "A side plank variation with the top leg supported on a bench, targeting the adductors and obliques. Keep your body straight and hips elevated.",
        "L-Sit":
            "An isometric hold with legs extended straight in front of you while supporting yourself on parallel bars or the floor. Requires core and hip flexor strength.",
        "Toe Touches":
            "A supine crunch reaching your hands toward your toes with legs extended vertically. Lift your shoulders off the ground and reach up.",
    ]
}
