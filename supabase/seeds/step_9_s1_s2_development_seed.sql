-- Development-only seed for the original S1 and S2 course JSON files.
-- Run this in the kaizora-development Supabase SQL Editor only.
-- Source of truth:
--   content/courses/S1_Computer_and_Internet_Readiness.json
--   content/courses/S2_AI_Toolkit_Setup.json
--
-- This script publishes the two setup courses, their modules and lessons,
-- lesson quizzes, and final assessments so Step 9 can be tested end to end.
-- It preserves the full lesson teaching content in lessons.content, keeps
-- quiz answer keys in the protected table, and stores prerequisites in
-- courses.source_metadata. It does not create learner accounts or enrolments.
--
-- Safe to re-run before assessment attempts exist. It refuses to rewrite
-- assessment questions after a learner has submitted an attempt. Existing
-- course/module/lesson IDs and learner lesson-progress rows are preserved.

begin;

do $$
begin
  if exists (
    select 1
    from public.assessment_attempts aa
    join public.assessments a on a.id = aa.assessment_id
    join public.courses c on c.id = a.course_id
    where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
  ) then
    raise exception 'S1/S2 seed stopped: assessment attempts already exist. Do not rewrite course questions after learners have attempted them.';
  end if;
end;
$$;

insert into public.course_categories (slug, name, description, display_order)
values ('setup-courses', 'Setup Courses', '', 1)
on conflict (slug) do update
set name = excluded.name,
    display_order = excluded.display_order;

insert into public.courses (
  category_id, slug, title, summary, description, difficulty,
  estimated_minutes, status, display_order, source_reference,
  source_metadata, published_at
)
select
  cat.id,
  'computer-and-internet-readiness',
  'Computer and Internet Readiness',
  'This course gets you ready for everything else at Kaizora AI Academy. You will learn what is inside a computer, how to find your way around Windows, how to keep your files tidy, how the internet works, how to use a browser, how to create a safe Google account, how to spot scams, and how to join an online class. Every lesson is short and every step is spelled out. If you get stuck, pause, breathe, and try the step again. Nobody is timing you.',
  'This course gets you ready for everything else at Kaizora AI Academy. You will learn what is inside a computer, how to find your way around Windows, how to keep your files tidy, how the internet works, how to use a browser, how to create a safe Google account, how to spot scams, and how to join an online class. Every lesson is short and every step is spelled out. If you get stuck, pause, breathe, and try the step again. Nobody is timing you.',
  'beginner',
  310,
  'published',
  1,
  'content/courses/S1_Computer_and_Internet_Readiness.json',
  '{"course_id":"S1","level":"Beginner","audience":"Beginner. Made for people who have never used a computer properly, or who feel nervous about it. No experience needed.","estimated_duration":"About 5 hours in total. Spread it over 2 weeks at 20 to 30 minutes a day so you never feel rushed.","what_you_will_need":[{"item":"A laptop or desktop computer","details":"Windows 10 or Windows 11 is best because the steps in this course use Windows. A Mac also works, and the lessons tell you where Mac is different. The computer must switch on, have a working keyboard and screen, and have some free storage space (at least 1 GB). Keep the charger nearby.","cost":"Paid (you may already own one)"},{"item":"Internet connection","details":"Home Wi-Fi, an office connection, or mobile data shared from your phone. You need a connection that can play a short YouTube video without stopping every few seconds. Videos use a lot of data, so Lesson 3.1 shows you how to lower video quality to save data.","cost":"Paid (Wi-Fi subscription or mobile data)"},{"item":"A web browser","details":"Windows already has Microsoft Edge. We will use Google Chrome in this course. If Chrome is not on your computer yet, Lesson 3.2 shows you how to get it. Both are free.","cost":"Free"},{"item":"A phone number that can receive text messages","details":"Google will send a code to your phone when you create your account in Lesson 4.1. Use a number you own and keep with you.","cost":"Free (use your existing number)"},{"item":"A Google account (you will create it in Lesson 4.1)","details":"You do not need one before you start. You will make one together with this course. It gives you a Gmail address, Google Drive and Google Meet.","cost":"Free"},{"item":"A notebook and a pen","details":"For writing down new words, answers to exercises and your backup codes. Keep the notebook somewhere safe at home.","cost":"Paid (very cheap)"},{"item":"Headphones or earphones","details":"Optional but helpful. They make video lessons easier to hear and they are useful for online classes.","cost":"Paid (optional)"},{"item":"A calm, patient mindset","details":"You will make mistakes, and that is completely fine. Every expert started exactly where you are. Take breaks. Finish one lesson at a time. You are allowed to repeat any lesson as many times as you like.","cost":"Free"}]}'::jsonb,
  now()
from public.course_categories cat
where cat.slug = 'setup-courses'
on conflict (slug) do update
set category_id = excluded.category_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    difficulty = excluded.difficulty,
    estimated_minutes = excluded.estimated_minutes,
    status = 'published',
    display_order = excluded.display_order,
    source_reference = excluded.source_reference,
    source_metadata = excluded.source_metadata,
    published_at = coalesce(public.courses.published_at, excluded.published_at);


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 1, 'Meet Your Computer', 'Understand what a computer is made of, switch it on and off correctly, move around the screen with confidence, and use the keyboard and mouse.',
       1, 'published'
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '1.1', 'What Is Inside a Computer?',
       20, 'https://www.youtube.com/watch?v=AkFi90lZmXA',
       '{"simple_explanation":"A computer is a machine that follows instructions very quickly. It is made of two kinds of things. Hardware is everything you can touch, like the screen and keyboard. Software is the set of instructions that tells the hardware what to do, like Windows or Google Chrome. You do not need to memorise how the inside works. You only need to know the main parts so that computer talk stops sounding strange.","step_by_step_guide":["Step 1: Sit somewhere comfortable and quiet with your notebook and pen next to you.","Step 2: Click the video link for this lesson. A YouTube page opens. Click the big play button (a triangle in the middle of the video).","Step 3: Watch the whole video once without pausing. It is short. You are not being tested. Just let the ideas wash over you.","Step 4: Watch it a second time. This time, pause (click the video once) every time the speaker names a part of the computer. Write each name in your notebook.","Step 5: Now look at your own computer. Find these parts and touch each one: the screen, the keyboard, the touchpad (the flat square under the keyboard) or the mouse, the power button, the charging port, and any USB ports (small rectangular holes on the side).","Step 6: Find the power button. Look at the symbol on it. It is usually a small circle with a short line at the top. Draw this symbol in your notebook so you recognise it.","Step 7: Copy this into your notebook in your own handwriting: The processor is the brain that does the thinking. Memory (RAM) is the short-term workspace that the computer uses while you are busy. Storage is the long-term cupboard where your files stay even when the computer is off.","Step 8: Write one example of hardware and one example of software in your notebook. For example, hardware: keyboard. Software: Google Chrome.","Step 9: Read the key terms below out loud once. Saying them aloud helps your brain remember them."],"key_terms":[{"term":"Hardware","meaning":"The parts of a computer that you can see and touch, like the screen, keyboard and mouse."},{"term":"Software","meaning":"The instructions and programs that run on the computer, like Windows or Chrome. You cannot touch software."},{"term":"Processor (CPU)","meaning":"The brain of the computer. It does the thinking and follows instructions."},{"term":"Memory (RAM)","meaning":"The short-term workspace. It holds what you are working on right now and is cleared when you switch the computer off."},{"term":"Storage","meaning":"The place where files are saved for the long term, even when the computer is off."}],"practical_exercise":{"task_title":"Label your own computer","instructions":"Take a sheet of paper. Draw a simple box for your computer. Draw arrows to the screen, keyboard, touchpad or mouse, power button, charging port and USB ports. Write the correct name next to each arrow. Then write two examples of hardware and two examples of software at the bottom of the page.","expected_outcome":"A labelled drawing with at least six parts named correctly, plus two examples of hardware and two of software."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 1
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '1.2', 'Starting Out With Windows: Desktop, Start Menu and Taskbar',
       25, 'https://www.youtube.com/watch?v=HDpZKtE06J4',
       '{"simple_explanation":"Windows is the main software on most laptops. It is called an operating system because it operates the whole computer for you. When you switch on, you see the desktop, which is like the top of a real desk. At the bottom is a bar called the taskbar, and in the middle or left of it is the Start button, which opens a list of everything on your computer.","step_by_step_guide":["Step 1: Click the video link. This video is long, so do not try to watch all of it today. Watch only the opening part about the desktop, the Start menu and the taskbar. Stop the video when it moves on to other topics.","Step 2: Press the power button once and wait. Do not keep pressing it. The screen will light up and show a lock screen with the time.","Step 3: Click anywhere on the lock screen, or press any key. A sign-in box appears. Type your PIN or password and press the Enter key. If you are the only person using the computer and it has no password, just press Enter.","Step 4: You are now on the desktop. This is the main screen. The picture behind everything is the wallpaper. The small pictures with names under them are icons. Each icon opens a program or a file when you double-click it (click twice quickly).","Step 5: Look at the bottom of the screen. The long bar is the taskbar. Find the Start button. It looks like four small squares, the Windows logo.","Step 6: Click the Start button once. A menu opens with a list of programs. Click an empty part of the desktop to close it. You can also press the Windows key on your keyboard, which has the same logo, to open and close it.","Step 7: Click the search box on the taskbar (it says Search). Type the word Notepad. When you see Notepad in the results, press Enter. A small window opens. This is a simple program for typing notes.","Step 8: Look at the top right corner of the window. There are three buttons. The line (minimise) hides the window to the taskbar. The square (maximise) makes it fill the screen. The X (close) shuts the program. Click the line, then click the Notepad icon on the taskbar to bring it back. Then click the X to close it.","Step 9: Always shut down properly. Click Start, click the power icon, then click Shut down. Wait until the screen goes fully black. Never hold the power button to switch off unless the computer is frozen.","Step 10: If you use a Mac, the bottom bar is called the Dock, the menu at the top left with the apple symbol replaces the Start button, and the three coloured circles in the top left of a window are close, minimise and maximise."],"key_terms":[{"term":"Operating system","meaning":"The main software that runs the computer. On most laptops it is Windows. On a Mac it is macOS."},{"term":"Desktop","meaning":"The main screen you see after signing in, with your wallpaper and icons."},{"term":"Taskbar","meaning":"The long bar at the bottom of the screen that shows the Start button and the programs that are open."},{"term":"Start menu","meaning":"The menu that opens when you click the Start button. It lists your programs and has the power button."},{"term":"Icon","meaning":"A small picture that stands for a program, file or folder."}],"practical_exercise":{"task_title":"Open, shrink and close Notepad","instructions":"Switch on your computer and sign in. Use the search box to open Notepad. Type your first name inside it. Click minimise, then bring it back from the taskbar. Click maximise, then click it again to make it smaller. Close it. When Windows asks if you want to save, click Don''t save. Finally, shut down your computer the correct way.","expected_outcome":"You opened Notepad from the search box, used all three window buttons, and shut the computer down properly."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 1
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '1.3', 'Keyboard, Mouse and Time-Saving Shortcuts',
       25, 'https://www.youtube.com/watch?v=CpDyDwTPEzo',
       '{"simple_explanation":"The keyboard is for typing and the mouse (or touchpad) is for pointing and clicking. A keyboard shortcut is a quick way to do something by pressing two keys together instead of hunting through menus. Learning just six shortcuts will save you hours over the next few months.","step_by_step_guide":["Step 1: Click the video link and watch the video about keyboard shortcuts. Pause it whenever you want to try a shortcut on your own computer.","Step 2: Open Notepad again using the search box on the taskbar, as you did in the last lesson.","Step 3: Look at your keyboard. The wide bar at the bottom is the Space bar and it makes a gap between words. The big key on the right is Enter and it starts a new line. The key at the top right with an arrow pointing left is Backspace and it erases the letter before the cursor. The cursor is the little blinking line that shows where your typing will appear.","Step 4: Type this sentence slowly: I am learning to use a computer. Use the Shift key (an up arrow on the left and right) together with a letter to make a capital letter. Hold Shift, tap the letter, then let go of both.","Step 5: Mouse practice. Move the mouse and watch the arrow on the screen. A single left click selects or presses something. A right click opens a small menu of choices. The wheel in the middle scrolls the page up and down.","Step 6: Touchpad practice if you have no mouse. Slide one finger to move the arrow. Tap once to left click. Tap with two fingers to right click. Slide two fingers up or down to scroll.","Step 7: Learn the shortcut pattern. Hold the first key down, tap the second key once, then let go of both. On a Mac, use the Command key where this lesson says Ctrl.","Step 8: Try Ctrl and A together. This selects everything you typed. It turns blue.","Step 9: Try Ctrl and C together. This copies what is selected. Click once at the end of your sentence, press Enter, then press Ctrl and V together. This pastes the copy. You now have the sentence twice.","Step 10: Press Ctrl and Z together. This is undo. The last thing you did is reversed. Undo is your best friend because it fixes mistakes.","Step 11: Write the six shortcuts in your notebook: Ctrl+C is copy, Ctrl+V is paste, Ctrl+X is cut (copy and remove), Ctrl+Z is undo, Ctrl+A is select all, Ctrl+S is save.","Step 12: Close Notepad with the X. If it asks to save, click Don''t save."],"key_terms":[{"term":"Cursor","meaning":"The small blinking line that shows where your typing will appear."},{"term":"Click","meaning":"Pressing the left mouse button once. A double-click is pressing it twice quickly."},{"term":"Right-click","meaning":"Pressing the right mouse button to open a menu of extra choices."},{"term":"Keyboard shortcut","meaning":"Pressing two or more keys together to do something fast, like Ctrl and C to copy."},{"term":"Undo","meaning":"A way to reverse your last action. The shortcut is Ctrl and Z."}],"practical_exercise":{"task_title":"Type, copy, paste and undo","instructions":"Open Notepad. Type a sentence about why you want to learn AI. Select everything with Ctrl+A, copy it with Ctrl+C, and paste it three times with Ctrl+V on new lines. Then press Ctrl+Z three times and watch the extra copies disappear. Close Notepad without saving.","expected_outcome":"You used select all, copy, paste and undo without clicking any menu."}}'::jsonb, 3, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 1
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 2, 'Files and Folders', 'Understand what files and folders are, and create a tidy folder system where you can always find your work.',
       2, 'published'
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '2.1', 'Understanding Files, Folders and File Explorer',
       20, 'https://www.youtube.com/watch?v=7oE1-PmNd8E',
       '{"simple_explanation":"Everything you save on a computer is a file. A photo, a typed document and a song are all files. A folder is like a real folder in an office drawer. You put related files inside it so you can find them later. File Explorer is the program that lets you look inside all your folders.","step_by_step_guide":["Step 1: Click the video link and watch the video about managing files and folders in Windows. Pause when you want to copy what the presenter does.","Step 2: Open File Explorer. Click the yellow folder icon on the taskbar at the bottom. If you do not see it, hold the Windows key and tap the letter E.","Step 3: Look at the left side of the window. You will see a list of places such as Desktop, Downloads, Documents and Pictures. Click Documents once. Its contents appear on the right.","Step 4: Look at the files. Each one has a name and a small picture. The picture tells you what kind of file it is. A yellow picture is a folder. Other pictures show photos, documents and so on.","Step 5: Learn the file type. At the end of a file name there can be a dot and a few letters, like .jpg for a photo, .pdf for a document that is hard to edit, .docx for a Word document and .txt for plain text. This ending is called the file extension.","Step 6: Show extensions. At the top of the window click View, then Show, then File name extensions. Now you can see the endings.","Step 7: Click Downloads on the left. This is the folder where Chrome puts everything you download from the internet. Remember this place because you will use it often.","Step 8: Click the back arrow at the top left to go back and the forward arrow to go forward, just like in a browser.","Step 9: If you use a Mac, the same program is called Finder. It is the blue smiling face icon in the Dock.","Step 10: In your notebook write: A file is one item. A folder is a container for files. File Explorer is how I look inside."],"key_terms":[{"term":"File","meaning":"One saved item, such as a photo, document, song or video."},{"term":"Folder","meaning":"A container that holds files, and other folders, so they stay organised."},{"term":"File Explorer","meaning":"The Windows program for looking at your files and folders. On a Mac it is called Finder."},{"term":"File extension","meaning":"The dot and letters at the end of a file name that show its type, like .pdf or .jpg."},{"term":"Downloads folder","meaning":"The usual place where files from the internet are saved."}],"practical_exercise":{"task_title":"Explore four folders","instructions":"Open File Explorer. Visit Documents, Downloads, Pictures and Desktop. In each folder, count how many items you can see and write the number in your notebook. Find one file with the extension .jpg or .png and one with .pdf or .docx, if you have them. Write the name and the extension of each.","expected_outcome":"A list in your notebook with four folder names, an item count for each, and at least one file with its extension."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 2
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '2.2', 'Creating, Renaming, Moving and Deleting Folders',
       25, 'https://www.youtube.com/watch?v=qrxAx1-AyZ4',
       '{"simple_explanation":"Now you will build your own filing system. A good system has clear folder names, and each file lives in the right folder. When your files are tidy you never waste time searching, and you never lose your work. This is a habit that will help you in every Kaizora course.","step_by_step_guide":["Step 1: Click the video link and watch how to create a folder in Windows 11. It is short. Replay it if anything is unclear.","Step 2: Open File Explorer and click Documents on the left.","Step 3: Right-click on an empty white space in the middle of the window (not on a file). A menu appears. Click New, then click Folder.","Step 4: A new folder appears and its name is highlighted in blue. Type Kaizora Academy and press Enter. If you click away by mistake, see Step 8 to rename it.","Step 5: Double-click your Kaizora Academy folder to open it. It is empty. Create another folder inside it by repeating Step 3. Name this one S1 Computer Readiness.","Step 6: Open the S1 Computer Readiness folder. Right-click an empty space, click New, then click Text Document. Name it My First Note and press Enter.","Step 7: Double-click My First Note to open it in Notepad. Type Hello, I made this file. Press Ctrl and S to save, then close Notepad with the X.","Step 8: To rename something, click it once so it is highlighted, then press the F2 key at the top of your keyboard. Type the new name and press Enter. You can also right-click it and choose Rename.","Step 9: To move a file, click it once, press Ctrl and X to cut it, open the other folder, then press Ctrl and V to paste it. You can also drag it with the mouse. Try moving My First Note up into the Kaizora Academy folder.","Step 10: To delete, click the file once and press the Delete key. It goes to the Recycle Bin, which is like a wastebasket. Nothing is gone for good yet. To bring it back, open the Recycle Bin from the desktop, right-click the file and choose Restore.","Step 11: Safety rule. Only delete files you created or recognise. If you do not know what a file is, leave it alone."],"key_terms":[{"term":"Right-click","meaning":"Pressing the right mouse button to open a menu of choices for the thing you clicked."},{"term":"Rename","meaning":"Changing the name of a file or folder."},{"term":"Cut and paste","meaning":"Cut removes an item and remembers it. Paste puts it in a new place. Together they move the item."},{"term":"Recycle Bin","meaning":"A holding place for deleted files. You can restore files from it until you empty it."}],"practical_exercise":{"task_title":"Build your Kaizora folder system","instructions":"Inside Documents, create a folder called Kaizora Academy. Inside it, create folders named S1 Computer Readiness, Notes and Projects. Create a text file called My First Note in Notes. Rename it to Day 1 Note. Move it into S1 Computer Readiness. Delete it, then restore it from the Recycle Bin.","expected_outcome":"A folder called Kaizora Academy with three folders inside it, and a file called Day 1 Note sitting in S1 Computer Readiness."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 2
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 3, 'The Internet and Your Browser', 'Understand in simple terms how the internet works and use Google Chrome to visit websites, search, and save pages.',
       3, 'published'
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '3.1', 'How the Internet Works',
       20, 'https://www.youtube.com/watch?v=7_LPdttKXPc',
       '{"simple_explanation":"The internet is a giant network of computers all over the world that are connected so they can send information to each other. When you open a website, your computer asks another computer, called a server, to send the page. The information travels in tiny pieces and arrives in a fraction of a second. You do not need to know every technical detail. You need the big picture.","step_by_step_guide":["Step 1: Click the video link. It is about five minutes long. Watch it once all the way through.","Step 2: Watch it again and pause when a new word appears, such as server or router. Write the word in your notebook.","Step 3: Understand the picture. Your phone or computer connects to a small box in your home or office called a router. The router connects to a company called an internet service provider, which connects to the wider internet. If you use mobile data, your phone connects to a mobile network instead.","Step 4: Check that you are connected. Look at the bottom right of the taskbar. Find the Wi-Fi symbol (curved lines) or a small globe or cable symbol. Click it. You will see the name of the network you are connected to.","Step 5: Learn how videos use your data. Videos use much more data than text. To save data on YouTube, click the gear icon at the bottom of a video, click Quality, and choose 360p or 480p instead of a high number like 1080p.","Step 6: Write down the answer to this question in your own words: When I open a website, what happens? A good answer is: My computer asks a server for the page, and the server sends it back in small pieces.","Step 7: Think about your own setup. Do you use Wi-Fi at home, an office connection or mobile data? Write it in your notebook so you remember which one you will use for this course."],"key_terms":[{"term":"Internet","meaning":"A worldwide network of connected computers that share information."},{"term":"Website","meaning":"A collection of pages stored on a computer called a server, which you can open with a browser."},{"term":"Server","meaning":"A powerful computer that stores websites and sends them to you when you ask."},{"term":"Router","meaning":"The small box that connects your devices to the internet through Wi-Fi or a cable."},{"term":"Wi-Fi","meaning":"A way of connecting to the internet through the air, without a cable."},{"term":"Data","meaning":"The amount of information you send and receive online. Videos use a lot."}],"practical_exercise":{"task_title":"Explain the internet to a friend","instructions":"Draw a simple picture with four boxes: your computer, a router, the internet, and a website server. Draw arrows between them. Then explain the picture out loud to a friend or family member in two or three sentences. If nobody is around, say it to yourself.","expected_outcome":"A drawing of four connected boxes and a clear spoken explanation of how a website reaches your screen."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 3
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '3.2', 'Using Google Chrome',
       25, 'https://www.youtube.com/watch?v=FFk0r5VFa_w',
       '{"simple_explanation":"A web browser is the program you use to visit websites. Google Chrome is one of the most popular ones and we will use it throughout Kaizora. At the top of Chrome is one long box called the address bar. You can type a website address or a question into it. Chrome also lets you keep many pages open in tabs and save favourites as bookmarks.","step_by_step_guide":["Step 1: Click the video link and watch the Chrome tutorial. Some buttons may look slightly different from your screen because Chrome updates often. The ideas stay the same.","Step 2: Check if Chrome is on your computer. Click the search box on the taskbar and type Chrome. If you see a round red, yellow, green and blue icon, click it. If not, open Microsoft Edge, type google.com/chrome in the address bar at the top, press Enter, click Download Chrome, then open the file from your Downloads folder and follow the instructions.","Step 3: Open Chrome. Look at the very long white bar at the top. This is the address bar.","Step 4: Click in the address bar, type wikipedia.org and press Enter. The Wikipedia website opens. A website address like this is called a URL.","Step 5: Use the arrows at the top left. The left arrow goes back to the page you were on before. The right arrow goes forward. The circular arrow reloads (refreshes) the page.","Step 6: Open a new tab. Click the plus (+) sign at the top, next to the current tab, or press Ctrl and T. Type bbc.com and press Enter. You now have two pages open and you can click each tab to switch.","Step 7: Close a tab. Click the small X on the tab, or press Ctrl and W. Close the BBC tab.","Step 8: Search the web. Click in the address bar, type how to boil rice and press Enter. Google shows a list of results. Be careful with results marked Sponsored or Ad. Those are paid. Click a result from a website you recognise.","Step 9: Save a bookmark. On a page you like, click the star at the right end of the address bar, then click Done. To see your saved pages, press Ctrl, Shift and B together to show the bookmarks bar under the address bar.","Step 10: View your history. Press Ctrl and H. This shows a list of pages you visited recently. You can use it to find a page you forgot to save.","Step 11: Find your downloads. Press Ctrl and J to see everything you downloaded with Chrome."],"key_terms":[{"term":"Browser","meaning":"A program for visiting websites, like Google Chrome, Microsoft Edge or Safari."},{"term":"Address bar","meaning":"The long box at the top of the browser where you type a web address or a search."},{"term":"URL","meaning":"A website address, like wikipedia.org."},{"term":"Tab","meaning":"A page you have open. You can have many tabs in one browser window."},{"term":"Bookmark","meaning":"A saved shortcut to a page you want to visit again."}],"practical_exercise":{"task_title":"Research and save three pages","instructions":"Open Chrome. Search for three things you are curious about, for example: what is artificial intelligence, best way to learn typing, and Lagos weather today. Open each result in its own tab. Bookmark one useful page from each search. Close all the tabs. Then open the bookmarks bar and open one of your bookmarks again.","expected_outcome":"Three bookmarked pages that open correctly from your bookmarks bar."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 3
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 4, 'Your Online Accounts', 'Create your own Google account with a professional email address, and protect it with a strong password and two-step verification.',
       4, 'published'
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '4.1', 'Creating Your Google Account',
       25, 'https://www.youtube.com/watch?v=ngKIz0FD1yw',
       '{"simple_explanation":"A Google account gives you a Gmail address plus access to Google Drive, Google Meet, YouTube and many other tools. At Kaizora you will use it to join classes and store your work. Choose your email address carefully, because you will be using it in the future for job applications and certificates.","step_by_step_guide":["Step 1: Click the video link and watch how to create a Google account. Google changes its screens from time to time, so your screens may look a little different. Follow the idea, not the exact picture.","Step 2: Have your phone next to you. Google will send a code by text message.","Step 3: Open Chrome. In the address bar type accounts.google.com/signup and press Enter.","Step 4: Type your first name and last name. Use your real name, because it will appear on your certificates. Click Next.","Step 5: Choose your birthday and gender from the drop-down menus. Click each box, pick an option from the list, then click Next.","Step 6: Choose your email address. Google suggests some options. Pick one like firstname.lastname or choose Create your own Gmail address and type it. Keep it professional. Avoid nicknames, jokes and lots of numbers. Gmail addresses always end with @gmail.com.","Step 7: Create a password. Make it at least 12 characters long. Next lesson explains how to make a strong one. Write it in your notebook and keep the notebook somewhere private at home. Click Next.","Step 8: Verify your phone number. Type your number, click Next, wait for the text message, then type the six-digit code into the box and click Verify.","Step 9: Add a recovery email if you have another one. This helps you get back into your account if you forget your password. You can skip it, but adding it is safer.","Step 10: Read the privacy and terms page, scroll down to the bottom, and click I agree.","Step 11: Test your new account. Go to mail.google.com. You should see your inbox. Click Compose (top left), type your own new email address in the To box, write Test in the subject, write Hello in the message, and click Send. Within seconds the email will appear in your inbox."],"key_terms":[{"term":"Account","meaning":"Your personal login on a service. It holds your name, settings and files."},{"term":"Gmail","meaning":"Google''s free email service. Your address ends with @gmail.com."},{"term":"Verification code","meaning":"A short number sent to your phone to prove it is really you."},{"term":"Recovery email","meaning":"A second email address used to get back into your account if you lose access."}],"practical_exercise":{"task_title":"Send yourself an email","instructions":"Finish creating your Google account. Open Gmail. Write a short email to yourself with the subject My first Kaizora email. In the message, write one sentence about what you want to learn. Send it, then open it from your inbox.","expected_outcome":"A new Google account and a received email in your own inbox."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 4
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '4.2', 'Strong Passwords and Two-Step Verification',
       25, 'https://www.youtube.com/watch?v=BXrozC8F2Fo',
       '{"simple_explanation":"A password is the key to your account. A weak key lets thieves in. Two-step verification is like adding a second lock: even if someone learns your password, they still cannot get in without a code from your phone. Setting this up takes about ten minutes and can save you a lot of trouble.","step_by_step_guide":["Step 1: Click the video link and watch the short video about protecting your account.","Step 2: Learn what makes a password strong. It is long (at least 12 characters), it is not based on your name or birthday, and you never use it on any other website.","Step 3: Try the four-word method. Pick four random words that do not belong together, join them with dashes, and add a number. Example only, do not use this one: purple-goat-river-lamp-47. It is long, easy to remember and hard to guess.","Step 4: Never share your password. Not with friends, not with people who message you on WhatsApp, and not with anyone who says they are from a bank or from Google.","Step 5: Turn on two-step verification. In Chrome go to myaccount.google.com and sign in if asked.","Step 6: On the left side, click Security. Scroll down to How you sign in to Google. Click 2-Step Verification.","Step 7: Click Get started and follow the instructions on the screen. Google will ask for your password again and then ask you to choose how to get the second step. Choose your phone. Follow the prompts and click Turn on when asked.","Step 8: Get backup codes. In the 2-Step Verification page, look for Backup codes. Click it and generate the codes. Write them in your notebook. If you lose your phone, these codes let you in.","Step 9: When Chrome asks Save password, click Save only if you are on your own personal computer. On a shared or cyber cafe computer, always click Never.","Step 10: Sign out and sign back in to test it. After you enter your password, Google should ask for the second step. Complete it. You are now much safer than before."],"key_terms":[{"term":"Password","meaning":"A secret word or phrase that proves you own an account."},{"term":"Two-step verification","meaning":"A second check after your password, usually a code sent to your phone."},{"term":"Backup codes","meaning":"A list of one-time codes you keep in a safe place in case you lose your phone."},{"term":"Reuse","meaning":"Using the same password on many websites. This is dangerous because one leak exposes all your accounts."}],"practical_exercise":{"task_title":"Lock your account properly","instructions":"Create a new strong password for your Google account using the four-word method. Change it at myaccount.google.com under Security. Turn on 2-Step Verification. Save your backup codes in your notebook. Sign out and sign in again to test it.","expected_outcome":"A strong new password, 2-Step Verification switched on, and backup codes saved safely."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 4
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 5, 'Staying Safe Online', 'Recognise common scam messages and know exactly what to do when something looks suspicious.',
       5, 'published'
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '5.1', 'Spotting Phishing and Scam Messages',
       25, 'https://www.youtube.com/watch?v=JlQovysQBn0',
       '{"simple_explanation":"Phishing is when a criminal sends you a message that pretends to be from a bank, a company or a friend, and tries to trick you into sharing a password, a code or money. These messages arrive by email, text, WhatsApp and social media. You do not need special software to stay safe. You need to slow down and check a few warning signs.","step_by_step_guide":["Step 1: Click the video link and watch the short video on how to recognise and report phishing.","Step 2: Learn the first warning sign: pressure. Scam messages try to rush you with words like urgent, act now, your account will be closed, or you have won. A real company will not threaten you in a rush.","Step 3: Learn the second warning sign: they ask for secrets. No real bank, Google or school will ever ask for your password, your card PIN, your BVN or the OTP code sent to your phone. If a message asks, it is a scam.","Step 4: Learn the third warning sign: the sender address. In an email, click or tap the sender name to see the full address. A fake message might show Google Support but the address could be something strange like support123@mail-random.xyz.","Step 5: Learn the fourth warning sign: links. On a computer, move your mouse over a link without clicking and look at the bottom left of the screen. It shows where the link really goes. If the address looks odd, do not click.","Step 6: Learn the fifth warning sign: too good to be true. Free money, a surprise scholarship, a loan with no checks, or a prize from a competition you never entered are all common scams.","Step 7: Learn the sixth warning sign: unexpected attachments. Never open a file from someone you do not know. Even when it looks like it came from a friend, ask them first if it is unexpected.","Step 8: Know what to do. Do not reply. Do not click. Do not open attachments. In Gmail, open the message, click the three dots at the top right of the message, and click Report phishing. Then delete it.","Step 9: If you already clicked or typed your password, act fast. Change your password at once, check that 2-Step Verification is on, and tell someone you trust.","Step 10: Write the golden rule in your notebook: Nobody real will ever ask for my password or OTP."],"key_terms":[{"term":"Phishing","meaning":"A trick where a message pretends to be from someone you trust to steal your information or money."},{"term":"OTP","meaning":"A one-time password, a short code sent to your phone that you must never share."},{"term":"Scam","meaning":"A dishonest plan to cheat you out of money or information."},{"term":"Attachment","meaning":"A file sent along with an email. Unknown attachments can carry viruses."}],"practical_exercise":{"task_title":"Scam or safe?","instructions":"Read these five messages and write Scam or Safe for each in your notebook, with one reason. 1) ''Your bank account will be blocked in 1 hour. Send your PIN to confirm.'' 2) ''Hi, your Kaizora class starts tomorrow at 6pm. Join with the link in your calendar invite.'' 3) ''Congratulations, you won 5 million naira. Click here to claim.'' 4) ''We noticed a login from a new device. If this was not you, change your password at myaccount.google.com.'' 5) ''Your OTP is 482913. Do not share it with anyone.''","expected_outcome":"Messages 1 and 3 marked as scams, message 2 marked as safe if it matches a real invite, and messages 4 and 5 marked as safe notifications as long as you never share the code. Each answer has a reason."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 5
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 6, 'Online Tools for Learning', 'Store and share files in Google Drive, and join and take part in an online class on Google Meet.',
       6, 'published'
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '6.1', 'Uploading Files to Google Drive',
       20, 'https://www.youtube.com/watch?v=mPdGDAxCZaw',
       '{"simple_explanation":"Google Drive is like a second hard drive that lives on the internet. Files you upload are saved safely online, so you can open them from any computer or phone by signing in. Every Google account comes with 15 GB of free space shared across Gmail, Drive and Photos. If your laptop breaks, your files in Drive are still safe.","step_by_step_guide":["Step 1: Click the video link and watch how to upload files and folders to Google Drive.","Step 2: Open Chrome and go to drive.google.com. Make sure you are signed in with your new Google account.","Step 3: Look at the left side. Click the big button that says New.","Step 4: Click Folder. A small box appears. Type Kaizora Academy and click Create. Your folder appears in the middle of the screen.","Step 5: Double-click the Kaizora Academy folder to open it.","Step 6: Click New again, then click File upload. A window from your computer opens. Go to Documents, then Kaizora Academy, then S1 Computer Readiness, click the note you made earlier, and click Open.","Step 7: Watch the bottom right of the screen. A small box shows a progress bar. When it says Upload complete, your file is safe in Drive.","Step 8: You can also drag a file from File Explorer straight onto the Drive page in Chrome. Try it with another file.","Step 9: Open a file in Drive by double-clicking it. Close it with the X in the top left.","Step 10: Remember that Drive also works from your phone through the Google Drive app, using the same account."],"key_terms":[{"term":"Google Drive","meaning":"Google''s online storage where you can keep files and open them from anywhere."},{"term":"Upload","meaning":"Sending a file from your computer to the internet."},{"term":"Download","meaning":"Bringing a file from the internet onto your computer."},{"term":"Cloud storage","meaning":"Storing files on computers connected to the internet instead of only on your own device."}],"practical_exercise":{"task_title":"Back up your first note","instructions":"In Google Drive, create a folder called Kaizora Academy. Upload the Day 1 Note file from your computer. Open it from Drive. Then download it to your Downloads folder again to see the difference between upload and download.","expected_outcome":"A Kaizora Academy folder in Drive that contains your note, and a downloaded copy in your Downloads folder."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '6.2', 'Sharing Files and Folders Safely',
       20, 'https://www.youtube.com/watch?v=86xLpRmWHLs',
       '{"simple_explanation":"Sharing in Drive lets other people see or work on your files without you sending them as attachments. You choose exactly who can open the file and what they are allowed to do. You will use this at Kaizora to share your projects with mentors.","step_by_step_guide":["Step 1: Click the video link and watch how to share files and folders in Google Drive. It is short.","Step 2: Open Google Drive. Right-click a file, for example your Day 1 Note, and click Share.","Step 3: In the box that says Add people, groups and calendar events, type the email address of the person you want to share with. If you are practising alone, use a second email address you own.","Step 4: Look at the role next to the email. Viewer means they can only look. Commenter means they can look and leave comments. Editor means they can change the file. Choose Viewer unless the person truly needs to change it.","Step 5: Click Send. The person receives an email with a link.","Step 6: To share with a link instead, click the General access section and choose Anyone with the link. Be careful. Anyone who gets that link can open the file, so only use this for things that are not private.","Step 7: Click Copy link to copy the link. You can then paste it into a message with Ctrl and V.","Step 8: To stop sharing, open Share again, click the role next to the person, and choose Remove access. Or change General access back to Restricted.","Step 9: Never share files that contain passwords, ID numbers or private photos."],"key_terms":[{"term":"Share","meaning":"Giving other people permission to open your file or folder."},{"term":"Viewer","meaning":"A person who can look at a file but not change it."},{"term":"Editor","meaning":"A person who can change the file."},{"term":"Restricted","meaning":"A setting that allows only the people you added to open the file."}],"practical_exercise":{"task_title":"Share a note as a viewer","instructions":"Share your Day 1 Note from Google Drive with a second email address (or a trusted classmate) as a Viewer. Check that the email arrives. Then remove their access and confirm it is no longer shared.","expected_outcome":"You shared the file as a Viewer, received or confirmed the invite, and then removed access."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '6.3', 'Joining a Class on Google Meet',
       20, 'https://www.youtube.com/watch?v=8iLQpC8QpiM',
       '{"simple_explanation":"Google Meet is a free tool for video calls. Many online classes use it, including classes at Kaizora. You can join from your computer or your phone. It is normal to feel shy at first. You can always keep your camera off and your microphone muted until you are ready.","step_by_step_guide":["Step 1: Click the video link and watch how to join a meeting in Google Meet.","Step 2: Put in your headphones if you have them. They make it easier to hear and stop echo.","Step 3: Open Chrome and go to meet.google.com. Make sure you are signed in to your Google account.","Step 4: Click New meeting, then click Start an instant meeting. This lets you practise alone. The first time, Chrome asks permission to use your microphone and camera. Click Allow.","Step 5: Look at the bottom bar. The microphone icon turns on and off your sound. The camera icon turns on and off your video. When an icon has a red line through it, it is off.","Step 6: Try each button. Turn your camera off and on. Turn your microphone off and on. Say a few words with your microphone on and see the small bars move to show it hears you.","Step 7: Click the red phone icon to leave the meeting.","Step 8: To join a real class, you will receive a link from your teacher. Click it, or go to meet.google.com, click in the box that says Enter a code or link, paste the link with Ctrl and V, and click Join.","Step 9: On the preview screen, check that you look and sound fine, then click Join now or Ask to join. If you ask to join, wait for the host to let you in.","Step 10: Tips for class: keep your microphone muted when you are not speaking, use the chat for questions, and turn your camera off if your data is low."],"key_terms":[{"term":"Google Meet","meaning":"Google''s free tool for video calls and online classes."},{"term":"Host","meaning":"The person who creates the meeting and lets others in."},{"term":"Mute","meaning":"Turning your microphone off so others cannot hear you."},{"term":"Meeting link","meaning":"A web address that takes you straight into a particular meeting."}],"practical_exercise":{"task_title":"Hold a meeting with yourself","instructions":"Start an instant meeting on Google Meet by yourself. Turn your camera and microphone off and on three times. Speak one full sentence and check the sound bars move. Copy the meeting link with the Copy link option, then leave the meeting.","expected_outcome":"You started and left a meeting, controlled your camera and microphone, and copied a meeting link."}}'::jsonb, 3, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '6.4', 'Sharing Your Screen in Google Meet',
       15, 'https://www.youtube.com/watch?v=91EV179tdL8',
       '{"simple_explanation":"Sharing your screen lets everyone in the meeting see what you see on your computer. It is how you will show your projects at Kaizora and how mentors will help you when you are stuck. You can choose to share only one window, which keeps the rest of your computer private.","step_by_step_guide":["Step 1: Click the video link and watch how to share your screen and view participants in Google Meet.","Step 2: Start an instant meeting by yourself, as you did in the last lesson.","Step 3: Open Notepad and type a few words in it so you have something to share. Go back to the Meet tab in Chrome.","Step 4: In the bottom bar, click Present now. The icon looks like a box with an arrow pointing up.","Step 5: A small menu asks what you want to share. Choose A window. This is the safest choice because only one window is shared.","Step 6: Click the Notepad window in the list and click Share. Everyone in the meeting now sees only that window.","Step 7: To stop, click Stop presenting. A bar usually appears near the bottom or top of your screen.","Step 8: Before sharing in a real class, close private tabs, emails and messages so nothing private appears on screen.","Step 9: Leave the meeting using the red phone icon."],"key_terms":[{"term":"Screen sharing","meaning":"Showing what is on your screen to the other people in a call."},{"term":"Present now","meaning":"The Meet button that starts screen sharing."},{"term":"Window","meaning":"One program''s box on your screen, like Notepad or a Chrome page."}],"practical_exercise":{"task_title":"Share one window","instructions":"Start an instant meeting alone. Open Notepad and type your name. Share only the Notepad window. Check that Meet says you are presenting. Stop presenting and leave the meeting.","expected_outcome":"You shared a single window and stopped sharing without leaving anything else visible."}}'::jsonb, 4, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.courses (
  category_id, slug, title, summary, description, difficulty,
  estimated_minutes, status, display_order, source_reference,
  source_metadata, published_at
)
select
  cat.id,
  'ai-toolkit-setup',
  'AI Toolkit Setup',
  'In this course you will set up the three AI assistants most people use today: ChatGPT, Claude and Gemini. You will have your first real conversations, learn how to write clear instructions (called prompts), learn why AI sometimes gets things wrong, practise checking its answers, and learn how to protect your private information. By the end you will have working accounts, a safe routine, and the confidence to use AI in every other Kaizora course.',
  'In this course you will set up the three AI assistants most people use today: ChatGPT, Claude and Gemini. You will have your first real conversations, learn how to write clear instructions (called prompts), learn why AI sometimes gets things wrong, practise checking its answers, and learn how to protect your private information. By the end you will have working accounts, a safe routine, and the confidence to use AI in every other Kaizora course.',
  'beginner',
  190,
  'published',
  2,
  'content/courses/S2_AI_Toolkit_Setup.json',
  '{"course_id":"S2","level":"Beginner","audience":"Beginner. Made for people who can use a browser and email but have never set up or used an AI assistant. If you have never used a computer properly, take Course S1 first for a smoother start.","estimated_duration":"About 3 hours in total. Spread it over 1 week at 20 to 30 minutes a day.","what_you_will_need":[{"item":"A laptop, desktop computer or a smartphone","details":"A computer is best because the lessons use a keyboard and a big screen. Windows or Mac both work. A phone also works for most steps, but typing long prompts is slower on a phone.","cost":"Paid (you may already own one)"},{"item":"Internet connection","details":"You need a connection that is stable enough to load websites and play YouTube videos. AI chats use little data, but the lesson videos use more. Lower the video quality to 360p or 480p if you are on mobile data.","cost":"Paid (Wi-Fi subscription or mobile data)"},{"item":"Google Chrome (or another modern browser)","details":"We use Chrome in the steps. If you do not have it, go to google.com/chrome and download it. Course S1 Lesson 3.2 shows how.","cost":"Free"},{"item":"A Google account","details":"You will use it to sign in to Gemini and, if you like, to sign in to the other tools. If you do not have one, create it at accounts.google.com/signup. Course S1 Lesson 4.1 walks you through it.","cost":"Free"},{"item":"An email address you can open right now","details":"The AI tools send a verification email or code. Keep your inbox open in another tab so you can copy the code quickly.","cost":"Free"},{"item":"A phone number that can receive text messages","details":"Some AI tools ask for a phone number to verify that you are a real person. Use your own number and keep your phone with you. If a tool is not available in your country or refuses your number, skip that tool. You only need one working assistant to continue.","cost":"Free (use your existing number)"},{"item":"A notebook and a pen","details":"For writing down new words, your account email addresses, and your exercise answers. Do not write your passwords here if other people can read your notebook.","cost":"Paid (very cheap)"},{"item":"A curious and careful mindset","details":"AI is a helpful tool, not a magic brain. It can be wrong, so we will practise checking its answers. Be curious, be patient with yourself, and be careful with your private information.","cost":"Free"}]}'::jsonb,
  now()
from public.course_categories cat
where cat.slug = 'setup-courses'
on conflict (slug) do update
set category_id = excluded.category_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    difficulty = excluded.difficulty,
    estimated_minutes = excluded.estimated_minutes,
    status = 'published',
    display_order = excluded.display_order,
    source_reference = excluded.source_reference,
    source_metadata = excluded.source_metadata,
    published_at = coalesce(public.courses.published_at, excluded.published_at);


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 1, 'Create Your AI Accounts', 'Set up free accounts for ChatGPT, Claude and Gemini so you have a working AI assistant ready for every future course.',
       1, 'published'
from public.courses c
where c.slug = 'ai-toolkit-setup'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '1.1', 'Creating Your ChatGPT Account',
       20, 'https://www.youtube.com/watch?v=9HtgDtpo2co',
       '{"simple_explanation":"ChatGPT is an AI assistant made by a company called OpenAI. You type a message and it replies in plain language. It can explain ideas, help you write, plan, summarise and brainstorm. A free plan exists, which is enough to follow this course. The free plan has limits on how much you can use it, and those limits can change, so do not be surprised if it asks you to wait sometimes.","step_by_step_guide":["Step 1: Click the video link and watch how to sign up for ChatGPT. The screens may look slightly different from yours because websites change often. Follow the idea, not the exact picture.","Step 2: Open Google Chrome. In the address bar at the top, type chatgpt.com and press Enter. Always type the address yourself. Do not click links from messages, because scammers copy these sites.","Step 3: Click the button that says Sign up. It is usually at the top right or in the middle of the page.","Step 4: Choose how to sign up. You can continue with your Google account or type an email address. If you pick Google, choose your account from the list and click it. If you pick email, type your email address and click Continue.","Step 5: If you used email, create a password. Make it long, with at least 12 characters. Use the four-word method from Course S1, for example three unrelated words and a number. Do not reuse your Gmail password.","Step 6: Check your email. Open your inbox in a new tab, find the message from OpenAI, and click the verification link or copy the code. Go back to the ChatGPT tab and paste the code if asked.","Step 7: ChatGPT may ask for your name and your date of birth. Use your real details. You may also be asked for a phone number to confirm you are a real person. Type it and enter the code that arrives by text message.","Step 8: When you reach the chat screen, you will see a message box at the bottom. Type: Hello, I am new to AI. What can you help me with? Press Enter and read the reply.","Step 9: Write in your notebook: ChatGPT is set up. Date: (today). Which sign-in method I used: (Google or email).","Step 10: Safety check. In the top corner of the page, check the web address says chatgpt.com. If you ever land on a site with a strange address that asks for your password, close it at once."],"key_terms":[{"term":"AI assistant","meaning":"A program you can chat with that answers questions and helps with tasks using artificial intelligence."},{"term":"Chatbot","meaning":"A computer program designed to have a conversation by text or voice."},{"term":"Free plan","meaning":"A version you can use without paying. It has limits on how much or how often you can use it."},{"term":"Sign up","meaning":"Creating a new account on a website."}],"practical_exercise":{"task_title":"Say hello to ChatGPT","instructions":"Create your ChatGPT account. Send your first message. Then send a second message: Explain what an AI assistant is in 3 short sentences for a complete beginner. Read the reply and write the three sentences in your notebook in your own words.","expected_outcome":"A working ChatGPT account, two messages sent, and three sentences in your notebook explaining what an AI assistant is."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 1
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '1.2', 'Creating Your Claude Account',
       25, 'https://www.youtube.com/watch?v=WSPChlfxJyA',
       '{"simple_explanation":"Claude is an AI assistant made by a company called Anthropic. It is good at writing, reading long documents and explaining things clearly. Like ChatGPT, it has a free plan with limits. Having more than one assistant is useful because each one answers a little differently, and you can compare their answers.","step_by_step_guide":["Step 1: Click the video link. It is a tutorial on how to use Claude. For now, you only need the opening part about getting started. You can watch the rest later when you feel comfortable.","Step 2: Open Chrome. In the address bar, type claude.ai and press Enter.","Step 3: Click the button to sign up or continue. You will see options such as Continue with Google or Continue with email.","Step 4: If you choose Continue with Google, click it and select your Google account. If you choose email, type your email address and click Continue.","Step 5: If you chose email, Claude sends a verification code or link to your inbox. Open your email in another tab, copy the code, return to the Claude tab and paste it into the box.","Step 6: Claude may ask for your name and ask you to confirm that you are an adult. Use your real name and answer honestly.","Step 7: You may be asked to verify your phone number. Type your number and enter the code sent by text message. If Claude does not accept your number or is not available in your area, skip this tool and move to the next lesson.","Step 8: When the chat screen appears, type: Hello, I am new to AI. Explain in simple words what you can help me with. Press Enter and read the reply.","Step 9: Notice how this reply is different from ChatGPT. Is it shorter or longer? Is it friendlier or more formal? Write one difference in your notebook.","Step 10: Check the address bar. It should say claude.ai. Never type your Claude password on a different address."],"key_terms":[{"term":"Claude","meaning":"An AI assistant made by the company Anthropic."},{"term":"Verification code","meaning":"A short number sent to your email or phone to prove that it is you."},{"term":"Prompt","meaning":"The message or instruction you type to an AI assistant."},{"term":"Compare","meaning":"Looking at two things side by side to see how they are alike and different."}],"practical_exercise":{"task_title":"Ask the same question twice","instructions":"In Claude, type: Explain what an AI assistant is in 3 short sentences for a complete beginner. Then open ChatGPT in a new tab and ask exactly the same thing. Write one way the two answers are alike and one way they are different.","expected_outcome":"A working Claude account and two comparison notes in your notebook."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 1
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '1.3', 'Getting Started With Google Gemini',
       20, 'https://www.youtube.com/watch?v=8aRJYpExTfs',
       '{"simple_explanation":"Gemini is the AI assistant made by Google. Because you already have a Google account, you can start almost at once. It works with other Google tools like Gmail and Google Drive, which makes it handy for school and work. It also has a free plan with limits.","step_by_step_guide":["Step 1: Click the video link. It is a long tutorial, so you do not need to watch all of it today. Watch the first few minutes about opening Gemini and sending your first message.","Step 2: Open Chrome. In the address bar, type gemini.google.com and press Enter.","Step 3: Sign in with the same Google account you created in Course S1. If you are already signed in to Chrome, you will land on the Gemini page straight away.","Step 4: If Gemini shows a welcome page or terms, read the short summary and click the button to continue. You may be asked about your age and your privacy choices.","Step 5: Find the message box at the bottom of the screen. Type: Hello, I am new to AI. What can you help me with? Press Enter.","Step 6: Read the reply. Look around the screen. You will see a menu on the left for your past chats and a button to start a new one.","Step 7: Try a second question: Give me 3 tips for learning a new skill in 30 minutes a day. Notice how the answer looks.","Step 8: Write in your notebook the three web addresses you now use: chatgpt.com, claude.ai and gemini.google.com.","Step 9: Bookmark each of the three sites. On each page, click the star at the right end of the address bar and click Done. Press Ctrl, Shift and B to show your bookmarks bar.","Step 10: If your account or country does not show Gemini, check that you are signed in and that your Google account is a personal account. If it still does not work, move on. You still have your other tools."],"key_terms":[{"term":"Gemini","meaning":"The AI assistant made by Google."},{"term":"Bookmark","meaning":"A saved shortcut to a web page."},{"term":"New chat","meaning":"A fresh conversation with a blank start, separate from your older chats."},{"term":"Chat history","meaning":"The list of your past conversations with an assistant."}],"practical_exercise":{"task_title":"Build your three-tool bookmark bar","instructions":"Open all three tools in separate tabs and bookmark each one. Send the same message to all three: Give me a 3-step plan to learn how to type faster. Notice which answer you like best and write one reason in your notebook.","expected_outcome":"Three bookmarks on your bookmarks bar and one sentence in your notebook explaining which answer you liked and why."}}'::jsonb, 3, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 1
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 2, 'Your First Conversations', 'Have your first chats with AI and learn how to write clear prompts that get useful answers.',
       2, 'published'
from public.courses c
where c.slug = 'ai-toolkit-setup'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '2.1', 'Your First Chat and a Tour of the Screen',
       20, 'https://www.youtube.com/watch?v=JzkZGGX3MxY',
       '{"simple_explanation":"Using an AI assistant is a bit like texting a very fast, very well-read friend who sometimes gets things wrong. You type a message in the box, press Enter and read the reply. You can reply again in the same chat and the assistant remembers what was said earlier in that chat. You do not need special words. You only need to say clearly what you want.","step_by_step_guide":["Step 1: Click the video link and watch the short beginner video about starting with ChatGPT. It is about five minutes long.","Step 2: Open ChatGPT with your bookmark. Look at the screen. At the bottom is the message box. On the left (or behind a menu button on a phone) is a list of your past chats and a button to start a new chat.","Step 3: Click the message box and type a clear question, for example: Explain what the internet is in simple words, like I am 12 years old. Press Enter.","Step 4: While the answer appears, notice the small buttons under it. One copies the text. Others let you rate the answer or ask for the answer again. Hover over each button with your mouse to see its name.","Step 5: Reply in the same chat. Type: Now give me one real-life example. Press Enter. The assistant remembers the first question because you are in the same conversation.","Step 6: Start a new chat using the New chat button. Type: What did I just ask you? Notice that the assistant does not know. A new chat starts with a blank memory of your earlier chats unless a memory feature is turned on.","Step 7: Go back to your first chat by clicking it in the list on the left. It is still there.","Step 8: Learn how to tidy up. Find the three dots next to a chat in the list. You can rename or delete a chat from there. Delete the new chat you just made.","Step 9: Repeat Step 3 in Claude and in Gemini, using the exact same question. Look at the three answers side by side.","Step 10: Write one thing you learned in your notebook, for example: Replying in the same chat lets me improve an answer."],"key_terms":[{"term":"Message box","meaning":"The place at the bottom of the screen where you type to the AI."},{"term":"Chat","meaning":"One conversation with an AI. The assistant remembers earlier messages in the same chat."},{"term":"Reply","meaning":"The answer the AI writes back to you."},{"term":"Follow-up","meaning":"A new message in the same chat that builds on what was said before."}],"practical_exercise":{"task_title":"A three-message conversation","instructions":"In one chat, ask the AI to explain something you are curious about. Then send a follow-up asking for a real-life example. Then send a third message asking it to shorten the explanation to two sentences. Copy the final two sentences into your notebook.","expected_outcome":"A single chat with three messages and a two-sentence summary in your notebook."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 2
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '2.2', 'Writing Clear Prompts and Improving Answers',
       30, 'https://www.youtube.com/watch?v=8yqcDL4TmzM',
       '{"simple_explanation":"The quality of the answer depends a lot on the quality of your instruction. If you ask something vague, the AI has to guess, and it often guesses wrong. If you give clear details, you get a much better answer. A good prompt has up to six parts: the task, the context, an example, a role for the AI, the format you want, and the tone. You do not need all six every time.","step_by_step_guide":["Step 1: Click the video link and watch the beginner video about mastering prompting. Pause when a new idea appears and write it in your notebook.","Step 2: Learn the six parts. Task: what you want done. Context: why you need it and who it is for. Example: a sample of what you like. Role: who the AI should act as. Format: how the answer should look, such as a list, a table or steps. Tone: how it should sound, such as friendly or formal.","Step 3: Try a vague prompt first. In ChatGPT type: Help me with my CV. Read the reply. Notice how general it is.","Step 4: Now try a clear prompt: Task: Write a short professional summary for my CV. Context: I am a final-year student in Ibadan looking for an internship in marketing. Role: Act as a career coach. Format: Two sentences. Tone: Confident but humble. Press Enter and compare.","Step 5: Use the clarifying trick. Type: Before you answer, ask me 5 questions to clarify what you need. Then answer the AI''s questions in your own words. This helps when you are not sure what details matter.","Step 6: Improve an answer with follow-ups instead of starting over. Try these in the same chat: Make it shorter. That is too advanced, explain it like I am brand new. Rewrite this as a checklist. Give me 3 options: simple, medium and advanced.","Step 7: Ask the AI to write the reusable prompt. Type: Create a reusable prompt that would produce the best result we arrived at. Use brackets for anything I should fill in next time.","Step 8: Save your best reusable prompt. Open Notepad or Google Docs, create a file called Prompt Library, and paste the prompt in. Name it with the goal, such as CV summary for students.","Step 9: Try the same clear prompt in Claude and Gemini. Notice that clear prompts work well in all three tools."],"key_terms":[{"term":"Prompt","meaning":"The instruction or question you type to an AI."},{"term":"Context","meaning":"Background details that help the AI understand your situation, like who the answer is for."},{"term":"Role","meaning":"A job or character you ask the AI to act as, such as career coach or teacher."},{"term":"Format","meaning":"The shape of the answer, such as a list, table, email or short paragraph."},{"term":"Iterate","meaning":"Improve an answer step by step with follow-up messages."}],"practical_exercise":{"task_title":"Turn a vague prompt into a clear one","instructions":"Pick a real task from your life, such as writing a message to a landlord, planning a study timetable or preparing for an interview. First send a vague one-line prompt. Then rewrite it using task, context, role, format and tone. Compare both answers. Save the clear prompt in a file called Prompt Library.","expected_outcome":"A vague prompt, a clear prompt, a short note on which answer was better, and a saved reusable prompt in your Prompt Library file."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 2
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.course_modules (
  course_id, module_number, title, goal, display_order, status
)
select c.id, 3, 'Using AI Safely and Wisely', 'Understand why AI sometimes makes things up, check its answers properly, and protect your private information.',
       3, 'published'
from public.courses c
where c.slug = 'ai-toolkit-setup'
on conflict (course_id, module_number) do update
set title = excluded.title,
    goal = excluded.goal,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '3.1', 'Why AI Sometimes Makes Things Up',
       20, 'https://www.youtube.com/watch?v=cfqtFvWOfg0',
       '{"simple_explanation":"AI assistants do not look up facts the way a library does. They predict which words are likely to come next, based on patterns they learned from huge amounts of text. Most of the time this works well. Sometimes it produces something that sounds confident and sensible but is false. This is called a hallucination. Knowing this will save you from many mistakes.","step_by_step_guide":["Step 1: Click the video link and watch the video on why large language models hallucinate. It may use a few technical words. Do not worry. You only need the main idea: the AI predicts words, it does not check facts.","Step 2: In your notebook, write this in your own words: A hallucination is when an AI gives a false answer that sounds confident.","Step 3: Run a safe experiment. In ChatGPT type: Tell me about the novel called The Silver River of Ibadan and its main characters. This book does not exist. See whether the AI admits it does not know it or invents details.","Step 4: Run the same experiment in Claude and in Gemini. Write down which tools admitted they did not know and which invented details.","Step 5: Now ask a question you already know the answer to, for example: What is the capital city of Nigeria? Notice that it answers correctly. AI is often right about common facts.","Step 6: Learn where mistakes are most common: exact numbers and statistics, dates, names of people, quotes, links and sources, small or local topics, recent events, and legal or medical details.","Step 7: Learn why it sounds confident. The AI writes in a smooth, certain tone even when it is wrong. A confident tone is not a sign of a correct answer.","Step 8: Learn the safe jobs for AI. Low-risk jobs: drafting, summarising text you give it, explaining ideas, brainstorming and rewriting. High-risk jobs: facts you will repeat to others, health, law, money and exam answers.","Step 9: Write your own rule in your notebook, for example: I will check names, numbers, dates and links before I trust or share an AI answer."],"key_terms":[{"term":"Hallucination","meaning":"When an AI gives a false or invented answer that sounds confident and believable."},{"term":"Large language model (LLM)","meaning":"The kind of AI behind chat assistants. It predicts the next words based on patterns in text it learned from."},{"term":"Training data","meaning":"The huge collection of text and other material an AI learned patterns from."},{"term":"Verify","meaning":"To check that something is true using a reliable source."}],"practical_exercise":{"task_title":"Catch an invented answer","instructions":"Ask two different AI assistants about something that does not exist, such as a made-up book, a made-up person or a made-up law. Write down what each one said. Mark which parts you believe are invented. Then ask each assistant: Are you sure this exists? and note the reply.","expected_outcome":"A written comparison of two assistants'' answers about a fake topic, with the invented parts clearly marked."}}'::jsonb, 1, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 3
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '3.2', 'Checking AI Answers Step by Step',
       25, 'https://www.youtube.com/watch?v=imBL73lFwbk',
       '{"simple_explanation":"Checking an AI answer does not have to be hard. You break the answer into small claims, pick the ones that matter, and check them with reliable sources. This takes a few minutes and protects you from sharing wrong information. It is a habit that serious professionals use every day.","step_by_step_guide":["Step 1: Click the video link and watch the demonstration of how to fact-check an AI answer claim by claim. Pause often and follow along in your notebook.","Step 2: Ask an AI a factual question. Type: Give me 5 facts about the history of Ibadan, each in one sentence. Read the answer.","Step 3: Break it into claims. Write each fact on its own line in your notebook. These are your claims.","Step 4: Mark the risky claims. Circle anything with a number, a date, a name or a quote. These need checking first.","Step 5: Check each circled claim with a reliable source. Open Chrome and search for it. Prefer government sites, universities, well-known news organisations and encyclopedias. Look for at least two sources that agree.","Step 6: If the AI gave you a link or a source, open every link. A source you cannot find, or a link that goes nowhere, may not exist.","Step 7: Ask the AI to help you check itself. Type: Which of these facts are you least sure about, and how could I verify each? Treat the answer as a guide, not as proof.","Step 8: Compare tools. Ask the same question in a second assistant. If the two answers disagree, that is a signal to check more carefully.","Step 9: For health, legal and money questions, use AI only to understand and prepare questions. Then talk to a qualified person such as a doctor, lawyer or bank officer.","Step 10: Write your three-step habit in your notebook: Break it into claims, check the risky ones, and ask a professional for high-stakes matters."],"key_terms":[{"term":"Claim","meaning":"One specific statement that can be true or false, such as a date or a number."},{"term":"Reliable source","meaning":"A trustworthy place for facts, like a university, a government site or a respected news organisation."},{"term":"Fact-check","meaning":"Checking whether information is true by comparing it with trusted sources."},{"term":"High-stakes","meaning":"Matters where a mistake could cause serious harm, such as health, law or money."}],"practical_exercise":{"task_title":"Fact-check five claims","instructions":"Ask an AI for five facts about any topic you like. Write each fact on its own line. Check each one with at least one reliable source. Mark each as Correct, Wrong or Could not confirm. Note one thing that surprised you.","expected_outcome":"A list of five claims, each marked Correct, Wrong or Could not confirm, with the source you used for each."}}'::jsonb, 2, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 3
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.lessons (
  module_id, lesson_number, title, estimated_minutes, youtube_url,
  content, display_order, status
)
select m.id, '3.3', 'Protecting Your Privacy and Your Accounts',
       30, 'https://www.youtube.com/watch?v=yt9pNziBbm0',
       '{"simple_explanation":"When you type something into an AI assistant, you are sending it to a company''s computers. Many companies may keep chats for a period and some may use them to improve their tools unless you change the settings. So the golden rule is simple: if you would not shout it in a public place, do not type it into an AI. You can also tighten your settings and keep your accounts safe with strong passwords and two-step verification.","step_by_step_guide":["Step 1: Click the video link. It is a long tutorial. Watch the part that talks about privacy and settings. You can pause and return later.","Step 2: Learn what you must never type into an AI: passwords, one-time codes (OTP), card numbers and PINs, your BVN or national ID number, private medical records, and private details about other people.","Step 3: Learn what to be careful with: your school or work documents, client information, and anything marked confidential. Get permission before pasting these. If in doubt, replace real names and numbers with made-up ones, such as Person A and Company X.","Step 4: Open ChatGPT and click your profile picture or name in a corner. Open Settings. Look for sections with names like Data controls, Personalization or Memory. Names change often, so look for these words.","Step 5: In Data controls, look for the option about improving the model for everyone. If you do not want your chats used for training, turn it off. Read what the option says before you change it.","Step 6: Look for Memory. Memory lets the assistant remember things about you between chats. Decide if you want it on. You can manage or turn it off if you prefer a clean start each time.","Step 7: Learn how to delete a chat. Hover over a chat in the left list, click the three dots and choose Delete. Delete any chat where you typed something private by mistake.","Step 8: Repeat a quick check in Claude and in Gemini. Open each tool''s settings and look for words like Privacy, Activity or Data. Read what is on by default and change what you are not happy with.","Step 9: Protect your accounts. For each AI account, use a strong, different password and turn on two-step verification if it is offered. This is the same two-step idea you set up for your Google account in Course S1.","Step 10: Public computers. If you use a cyber cafe or a shared computer, always sign out when you finish and never let the browser save your password."],"key_terms":[{"term":"Privacy","meaning":"Your right to keep personal information to yourself."},{"term":"Sensitive information","meaning":"Private details like passwords, ID numbers, card numbers and health records."},{"term":"Memory (in AI)","meaning":"A feature that lets an assistant remember facts about you across chats."},{"term":"Data controls","meaning":"Settings that let you choose how your chats and information are stored or used."},{"term":"Confidential","meaning":"Private information that should not be shared without permission."}],"practical_exercise":{"task_title":"Do a privacy check-up","instructions":"Open settings in ChatGPT, Claude and Gemini. For each, write down three things: where the privacy or data settings are, whether your chats may be used to improve the tool, and whether memory is on. Change any setting you are not comfortable with. Then write your own list of 5 things you will never type into an AI.","expected_outcome":"A page in your notebook with the settings notes for three tools and your personal list of five things you will never type into an AI."}}'::jsonb, 3, 'published'
from public.course_modules m
join public.courses c on c.id = m.course_id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 3
on conflict (module_id, lesson_number) do update
set title = excluded.title,
    estimated_minutes = excluded.estimated_minutes,
    youtube_url = excluded.youtube_url,
    content = excluded.content,
    display_order = excluded.display_order,
    status = 'published';


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '1.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 1
  and l.lesson_number = '1.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '1.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 1
  and l.lesson_number = '1.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '1.3 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 1
  and l.lesson_number = '1.3'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '2.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 2
  and l.lesson_number = '2.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '2.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 2
  and l.lesson_number = '2.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '3.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 3
  and l.lesson_number = '3.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '3.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 3
  and l.lesson_number = '3.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '4.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 4
  and l.lesson_number = '4.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '4.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 4
  and l.lesson_number = '4.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '5.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 5
  and l.lesson_number = '5.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '6.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
  and l.lesson_number = '6.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '6.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
  and l.lesson_number = '6.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '6.3 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
  and l.lesson_number = '6.3'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '6.4 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'computer-and-internet-readiness'
  and m.module_number = 6
  and l.lesson_number = '6.4'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, null, 'final_assessment',
       'Computer and Internet Readiness Final Assessment', '',
       80, 3, 'published', 1
from public.courses c
where c.slug = 'computer-and-internet-readiness'
on conflict (course_id) where assessment_type = 'final_assessment' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '1.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 1
  and l.lesson_number = '1.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '1.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 1
  and l.lesson_number = '1.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '1.3 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 1
  and l.lesson_number = '1.3'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '2.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 2
  and l.lesson_number = '2.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '2.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 2
  and l.lesson_number = '2.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '3.1 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 3
  and l.lesson_number = '3.1'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '3.2 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 3
  and l.lesson_number = '3.2'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, l.id, 'lesson_quiz',
       '3.3 Knowledge Check', '',
       70, 3, 'published', 1
from public.courses c
join public.course_modules m on m.course_id = c.id
join public.lessons l on l.module_id = m.id
where c.slug = 'ai-toolkit-setup'
  and m.module_number = 3
  and l.lesson_number = '3.3'
on conflict (lesson_id) where assessment_type = 'lesson_quiz' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


insert into public.assessments (
  course_id, lesson_id, assessment_type, title, instructions,
  passing_score_percentage, max_attempts, status, display_order
)
select c.id, null, 'final_assessment',
       'AI Toolkit Setup Final Assessment', '',
       80, 3, 'published', 1
from public.courses c
where c.slug = 'ai-toolkit-setup'
on conflict (course_id) where assessment_type = 'final_assessment' do update
set title = excluded.title,
    instructions = excluded.instructions,
    passing_score_percentage = excluded.passing_score_percentage,
    max_attempts = excluded.max_attempts,
    status = 'published',
    display_order = excluded.display_order;


delete from public.assessment_questions q
using public.assessments a, public.courses c
where q.assessment_id = a.id
  and a.course_id = c.id
  and c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup');


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which of these is hardware?', '[{"key":"A","text":"Google Chrome"},{"key":"B","text":"The keyboard"},{"key":"C","text":"Windows"},{"key":"D","text":"A website"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '1.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Hardware is anything you can touch. You can touch a keyboard. Chrome, Windows and websites are software.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is storage used for?', '[{"key":"A","text":"Keeping files for a long time, even when the computer is off"},{"key":"B","text":"Making the screen brighter"},{"key":"C","text":"Connecting to Wi-Fi"},{"key":"D","text":"Cooling the computer down"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '1.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Storage is the long-term cupboard of the computer. Your files stay there until you delete them.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What does the minimise button (the line) do?', '[{"key":"A","text":"Closes the program for good"},{"key":"B","text":"Hides the window down to the taskbar"},{"key":"C","text":"Deletes the file"},{"key":"D","text":"Turns off the computer"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '1.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Minimise only hides the window. The program is still running and you can bring it back by clicking its icon on the taskbar.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is the safest way to switch off a Windows computer?', '[{"key":"A","text":"Hold the power button until it goes dark"},{"key":"B","text":"Close the laptop lid"},{"key":"C","text":"Click Start, then the power icon, then Shut down"},{"key":"D","text":"Pull out the charger"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '1.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'C', 'Shutting down properly lets Windows save its work and close everything safely.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which shortcut copies something you have selected?', '[{"key":"A","text":"Ctrl and V"},{"key":"B","text":"Ctrl and Z"},{"key":"C","text":"Ctrl and C"},{"key":"D","text":"Ctrl and S"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '1.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'C', 'C stands for copy. V is paste, Z is undo and S is save.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'You pressed a wrong key and deleted a paragraph by mistake. What is the fastest fix?', '[{"key":"A","text":"Start typing it again"},{"key":"B","text":"Press Ctrl and Z"},{"key":"C","text":"Restart the computer"},{"key":"D","text":"Press Ctrl and V"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '1.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Ctrl and Z is undo. It reverses your most recent action.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is a folder?', '[{"key":"A","text":"A program for typing"},{"key":"B","text":"A container that holds files"},{"key":"C","text":"A kind of virus"},{"key":"D","text":"A website"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '2.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'A folder is where you keep related files together.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'Where do files you download from the internet usually go?', '[{"key":"A","text":"The Recycle Bin"},{"key":"B","text":"The Downloads folder"},{"key":"C","text":"The Start menu"},{"key":"D","text":"The taskbar"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '2.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Chrome and most browsers save downloads in the Downloads folder by default.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'How do you open the menu to create a new folder?', '[{"key":"A","text":"Double-click the desktop"},{"key":"B","text":"Right-click an empty space and choose New, then Folder"},{"key":"C","text":"Press the power button"},{"key":"D","text":"Press Ctrl and Z"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '2.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Right-clicking on an empty space opens a menu that has the New option.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'You deleted a file by mistake. What can you do?', '[{"key":"A","text":"Nothing, it is gone forever"},{"key":"B","text":"Open the Recycle Bin and restore it"},{"key":"C","text":"Restart the computer"},{"key":"D","text":"Reinstall Windows"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '2.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Deleted files go to the Recycle Bin first, so you can restore them until the bin is emptied.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is a server?', '[{"key":"A","text":"A computer that stores websites and sends them to you"},{"key":"B","text":"A type of keyboard"},{"key":"C","text":"A video game"},{"key":"D","text":"A cable for charging"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '3.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Websites live on servers, which send pages to your device when you open them.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'How can you save mobile data when watching YouTube?', '[{"key":"A","text":"Turn up the volume"},{"key":"B","text":"Lower the video quality"},{"key":"C","text":"Use a bigger screen"},{"key":"D","text":"Close the keyboard"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '3.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Lower quality such as 360p uses much less data than high quality such as 1080p.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is the address bar used for?', '[{"key":"A","text":"Typing a website address or a search"},{"key":"B","text":"Changing the screen brightness"},{"key":"C","text":"Deleting files"},{"key":"D","text":"Turning on Wi-Fi"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '3.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The address bar at the top of the browser accepts both web addresses and search questions.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'Which shortcut opens a new tab in Chrome?', '[{"key":"A","text":"Ctrl and T"},{"key":"B","text":"Ctrl and Q"},{"key":"C","text":"Ctrl and P"},{"key":"D","text":"Ctrl and F"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '3.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'T stands for tab. Ctrl and T opens a fresh tab.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Why should you choose a professional email address?', '[{"key":"A","text":"Because you will use it for certificates and job applications"},{"key":"B","text":"Because it makes the internet faster"},{"key":"C","text":"Because Google requires nicknames"},{"key":"D","text":"Because it costs less"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '4.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'People will see your email address in applications and certificates, so keep it neat and sensible.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is the verification code sent to your phone for?', '[{"key":"A","text":"To prove it is really you"},{"key":"B","text":"To speed up your phone"},{"key":"C","text":"To change your wallpaper"},{"key":"D","text":"To order data"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '4.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The code shows that you own the phone number you entered.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which password is the strongest?', '[{"key":"A","text":"12345678"},{"key":"B","text":"myname2000"},{"key":"C","text":"purple-goat-river-lamp-47"},{"key":"D","text":"password"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '4.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'C', 'It is long and made of unrelated words. The others are short, common or easy to guess.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What does two-step verification protect you from?', '[{"key":"A","text":"Someone using your password alone to get in"},{"key":"B","text":"Slow internet"},{"key":"C","text":"Low battery"},{"key":"D","text":"A cracked screen"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '4.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Even if a thief learns your password, they still need the second step from your phone.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Someone calls and says they are from your bank and asks for the OTP sent to your phone. What do you do?', '[{"key":"A","text":"Give it to them quickly"},{"key":"B","text":"Refuse and hang up, because a real bank never asks for it"},{"key":"C","text":"Share only half of it"},{"key":"D","text":"Send it by WhatsApp"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '5.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Real banks never ask for your OTP. Anyone who does is trying to steal your money.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What can you do to check where a link really goes on a computer?', '[{"key":"A","text":"Click it fast"},{"key":"B","text":"Hover the mouse over it and read the address at the bottom of the screen"},{"key":"C","text":"Forward it to ten friends"},{"key":"D","text":"Restart the computer"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '5.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Hovering shows the real destination without opening the page.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What does upload mean?', '[{"key":"A","text":"Sending a file from your computer to the internet"},{"key":"B","text":"Deleting a file"},{"key":"C","text":"Printing a file"},{"key":"D","text":"Renaming a file"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Upload moves a copy of the file from your device to online storage. Download is the opposite.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'Why is Google Drive useful if your laptop breaks?', '[{"key":"A","text":"Your files are still safe online and can be opened from another device"},{"key":"B","text":"It repairs the laptop"},{"key":"C","text":"It deletes your files"},{"key":"D","text":"It speeds up your Wi-Fi"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Files in Drive live online, so they survive even when your device is lost or broken.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which role lets a person look at your file but not change it?', '[{"key":"A","text":"Editor"},{"key":"B","text":"Owner"},{"key":"C","text":"Viewer"},{"key":"D","text":"Admin"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'C', 'Viewers can open the file but cannot make changes.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What does Anyone with the link mean?', '[{"key":"A","text":"Only you can open the file"},{"key":"B","text":"Anybody who has the link can open it"},{"key":"C","text":"Only Google employees can open it"},{"key":"D","text":"The file is deleted"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'It is convenient but less private, so use it only for files that are safe to be seen by many people.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What should you do with your microphone when you are not speaking in a class?', '[{"key":"A","text":"Keep it muted"},{"key":"B","text":"Keep it loud"},{"key":"C","text":"Turn it into a camera"},{"key":"D","text":"Unplug the computer"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Muting reduces background noise for everyone.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'How can you save data during an online class?', '[{"key":"A","text":"Turn your camera off"},{"key":"B","text":"Turn the volume up"},{"key":"C","text":"Open more tabs"},{"key":"D","text":"Close the microphone permanently"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Video uses a lot of data. Switching your camera off reduces data use.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which sharing option is safest when you only want to show one program?', '[{"key":"A","text":"Your entire screen"},{"key":"B","text":"A window"},{"key":"C","text":"Nothing"},{"key":"D","text":"Everything on every device"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.4'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Sharing a single window keeps the rest of your screen private.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What should you do before sharing your screen in a real class?', '[{"key":"A","text":"Close private tabs and messages"},{"key":"B","text":"Turn on every program"},{"key":"C","text":"Open your bank account"},{"key":"D","text":"Delete your files"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'computer-and-internet-readiness'
    and l.lesson_number = '6.4'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Anything open on your screen could be seen, so tidy up first.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which of these is hardware?', '[{"key":"A","text":"Windows"},{"key":"B","text":"Google Chrome"},{"key":"C","text":"A mouse"},{"key":"D","text":"A website"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'C', 'Hardware is anything you can touch. A mouse is a physical device.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is the job of the taskbar in Windows?', '[{"key":"A","text":"It shows the Start button and the programs that are open"},{"key":"B","text":"It stores your files for ever"},{"key":"C","text":"It connects you to Wi-Fi"},{"key":"D","text":"It shuts down the router"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The taskbar sits at the bottom of the screen and holds the Start button and open programs.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 3, 'Which shortcut undoes your last action?', '[{"key":"A","text":"Ctrl and Z"},{"key":"B","text":"Ctrl and C"},{"key":"C","text":"Ctrl and S"},{"key":"D","text":"Ctrl and A"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Z stands for undo.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 4, 'What is the best way to switch off a Windows computer?', '[{"key":"A","text":"Click Start, the power icon, then Shut down"},{"key":"B","text":"Hold the power button every time"},{"key":"C","text":"Close the lid and walk away"},{"key":"D","text":"Unplug it"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Shutting down properly protects your files and the system.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 5, 'What is the difference between a file and a folder?', '[{"key":"A","text":"A file is one item, a folder holds files"},{"key":"B","text":"They are the same thing"},{"key":"C","text":"A file holds folders, a folder is one item"},{"key":"D","text":"A folder is a program"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Files are single items. Folders are containers that organise them.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 6, 'Where do deleted files go first in Windows?', '[{"key":"A","text":"The Recycle Bin"},{"key":"B","text":"Google Drive"},{"key":"C","text":"The Start menu"},{"key":"D","text":"They vanish at once"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'You can restore deleted files from the Recycle Bin until you empty it.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 7, 'How do you rename a selected file quickly?', '[{"key":"A","text":"Press F2"},{"key":"B","text":"Press Alt and F4"},{"key":"C","text":"Press Tab"},{"key":"D","text":"Press Caps Lock"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'F2 lets you type a new name.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 8, 'What is a router?', '[{"key":"A","text":"A device that connects your devices to the internet"},{"key":"B","text":"A kind of browser"},{"key":"C","text":"A folder"},{"key":"D","text":"A video"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The router shares your internet connection with devices at home or work.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 9, 'What is the address bar used for in Chrome?', '[{"key":"A","text":"Typing a web address or a search"},{"key":"B","text":"Changing your password"},{"key":"C","text":"Making a call"},{"key":"D","text":"Deleting emails"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The address bar accepts both website addresses and searches.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 10, 'How can you reduce data use when watching YouTube?', '[{"key":"A","text":"Choose a lower video quality such as 360p"},{"key":"B","text":"Increase the brightness"},{"key":"C","text":"Use more tabs"},{"key":"D","text":"Mute the video"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Lower quality means smaller video data.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 11, 'Which email address is the most professional?', '[{"key":"A","text":"ada.obi@gmail.com"},{"key":"B","text":"sweetgirl_xoxo99@gmail.com"},{"key":"C","text":"lordofthegame777@gmail.com"},{"key":"D","text":"notmyrealname2020@gmail.com"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A simple address based on your real name looks professional on certificates and applications.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 12, 'What is the purpose of a verification code sent to your phone?', '[{"key":"A","text":"To prove you own the phone number or account"},{"key":"B","text":"To change your wallpaper"},{"key":"C","text":"To increase your data"},{"key":"D","text":"To delete your emails"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'It confirms it is really you signing up or signing in.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 13, 'Which of these is a strong password?', '[{"key":"A","text":"password123"},{"key":"B","text":"ada1990"},{"key":"C","text":"purple-goat-river-lamp-47"},{"key":"D","text":"qwerty"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'C', 'It is long and made of unrelated words, so it is hard to guess.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 14, 'What does two-step verification add?', '[{"key":"A","text":"A second check after your password"},{"key":"B","text":"A faster computer"},{"key":"C","text":"More storage"},{"key":"D","text":"A new keyboard"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Even if someone steals your password, they cannot sign in without the second step.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 15, 'A message says your bank account will be blocked unless you send your PIN. What is it?', '[{"key":"A","text":"A scam"},{"key":"B","text":"A normal bank notice"},{"key":"C","text":"A prize"},{"key":"D","text":"A school announcement"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Banks never ask for your PIN, and pressure to act fast is a classic scam sign.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 16, 'What should you never share with anyone, even if they say they are from your bank?', '[{"key":"A","text":"Your OTP code and password"},{"key":"B","text":"Your first name"},{"key":"C","text":"The weather"},{"key":"D","text":"Your favourite colour"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'OTPs and passwords give access to your account and must stay secret.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 17, 'What does upload mean?', '[{"key":"A","text":"Sending a file from your device to the internet"},{"key":"B","text":"Bringing a file from the internet to your device"},{"key":"C","text":"Deleting a file"},{"key":"D","text":"Renaming a file"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Upload sends a file online. Download brings it to your device.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 18, 'Which sharing role lets someone look at your file but not change it?', '[{"key":"A","text":"Viewer"},{"key":"B","text":"Editor"},{"key":"C","text":"Owner"},{"key":"D","text":"Admin"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Viewers can read the file only.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 19, 'In Google Meet, what does a red line through the microphone icon mean?', '[{"key":"A","text":"Your microphone is muted"},{"key":"B","text":"Your camera is on"},{"key":"C","text":"The meeting is recording"},{"key":"D","text":"Your battery is full"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A red line means the microphone is off and no one can hear you.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 20, 'What is the safest way to share your screen in a class when you only want to show one program?', '[{"key":"A","text":"Share a single window"},{"key":"B","text":"Share your entire screen with every tab open"},{"key":"C","text":"Share your bank website"},{"key":"D","text":"Share your password page"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'computer-and-internet-readiness'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Sharing a single window keeps the rest of your screen private.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is the safest way to reach the ChatGPT website?', '[{"key":"A","text":"Click a link a stranger sent on WhatsApp"},{"key":"B","text":"Type chatgpt.com yourself in the address bar"},{"key":"C","text":"Search for a free cracked version"},{"key":"D","text":"Open any website that says ChatGPT in the name"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '1.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'Typing the official address yourself protects you from fake copies of the website.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What does the free plan usually mean?', '[{"key":"A","text":"You can use it with some limits"},{"key":"B","text":"You can use it with no limits ever"},{"key":"C","text":"You must pay later without being told"},{"key":"D","text":"It works without the internet"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '1.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Free plans work, but they limit how much or how often you can use the tool.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Why is it useful to have more than one AI assistant?', '[{"key":"A","text":"You can compare their answers"},{"key":"B","text":"They never make mistakes together"},{"key":"C","text":"It makes your computer faster"},{"key":"D","text":"It removes the need for passwords"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '1.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Different assistants answer differently, so comparing them helps you spot weak or wrong answers.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is a prompt?', '[{"key":"A","text":"The instruction or message you type to an AI"},{"key":"B","text":"A type of internet cable"},{"key":"C","text":"A password reset email"},{"key":"D","text":"A kind of virus"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '1.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A prompt is whatever you type to tell the AI what you want.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which website do you type to open Gemini?', '[{"key":"A","text":"gemini.google.com"},{"key":"B","text":"gemini-free-download.xyz"},{"key":"C","text":"openai.com/gemini-login"},{"key":"D","text":"claude.ai"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '1.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'gemini.google.com is Google''s official address for Gemini.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'Why is it useful to bookmark your AI tools?', '[{"key":"A","text":"You can reach the real website quickly without clicking risky links"},{"key":"B","text":"It makes the tools free for ever"},{"key":"C","text":"It removes the need for a password"},{"key":"D","text":"It speeds up your internet"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '1.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Bookmarks take you to the real site every time, which protects you from fake copies.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is a follow-up message?', '[{"key":"A","text":"A new message in the same chat that builds on earlier ones"},{"key":"B","text":"A message that deletes the chat"},{"key":"C","text":"A message that logs you out"},{"key":"D","text":"A message to a stranger"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '2.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Follow-ups let you improve and shape an answer without starting from the beginning.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'You start a brand new chat. What should you expect?', '[{"key":"A","text":"The AI starts fresh and does not know what you said in other chats"},{"key":"B","text":"The AI remembers every word from every chat"},{"key":"C","text":"The AI deletes your account"},{"key":"D","text":"The AI turns off"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '2.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A new chat begins with a clean start unless a special memory feature is switched on.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which prompt is clearer?', '[{"key":"A","text":"Help me with my CV"},{"key":"B","text":"Write a 2-sentence CV summary for a final-year marketing student, in a confident tone"},{"key":"C","text":"CV"},{"key":"D","text":"Do something with my paper"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '2.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'B', 'It states the task, the length, the person and the tone. The others leave the AI to guess.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is a good way to improve an answer you do not like?', '[{"key":"A","text":"Reply in the same chat and say what to change"},{"key":"B","text":"Close the computer"},{"key":"C","text":"Delete your account"},{"key":"D","text":"Type the same question ten times"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '2.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Follow-up instructions like make it shorter or simpler help the AI correct itself.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Why do AI assistants sometimes make things up?', '[{"key":"A","text":"They predict likely words and do not check facts"},{"key":"B","text":"They look up every answer in a library"},{"key":"C","text":"They are always lying on purpose"},{"key":"D","text":"Their screens are too small"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '3.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The AI generates text from patterns. It has no built-in fact check, so it can produce confident but false statements.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'Which of these is the riskiest thing to trust without checking?', '[{"key":"A","text":"An exact statistic with a source link"},{"key":"B","text":"A synonym for the word happy"},{"key":"C","text":"A rhyme for the word cat"},{"key":"D","text":"A friendly greeting"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '3.1'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Numbers and links are common places for AI mistakes, so they need checking.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is the first thing to do when you want to check a long AI answer?', '[{"key":"A","text":"Break it into small claims"},{"key":"B","text":"Share it at once"},{"key":"C","text":"Delete it"},{"key":"D","text":"Ask the AI to say it louder"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '3.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Small claims are easier to check one by one.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'The AI gives you a link as a source but the page does not exist. What should you assume?', '[{"key":"A","text":"The source may be invented, so do not rely on it"},{"key":"B","text":"The internet is broken"},{"key":"C","text":"The AI is always correct"},{"key":"D","text":"You must have typed the link wrong in a dream"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '3.2'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'AI sometimes invents links and sources, so always open them to see if they are real.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'Which of these should you never type into an AI assistant?', '[{"key":"A","text":"Your bank PIN or OTP"},{"key":"B","text":"A question about cooking rice"},{"key":"C","text":"A request to rewrite a polite email"},{"key":"D","text":"A request to explain what the internet is"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '3.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'PINs and OTP codes give access to your money and accounts and must stay secret.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'You have to share a client letter with an AI to rewrite it. What is the safest approach?', '[{"key":"A","text":"Replace real names and numbers with made-up ones first, and get permission"},{"key":"B","text":"Paste everything as it is"},{"key":"C","text":"Post it publicly"},{"key":"D","text":"Send it to ten friends"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  join public.lessons l on l.id = a.lesson_id
     join public.course_modules m on m.id = l.module_id
     and a.assessment_type = 'lesson_quiz'
  where c.slug = 'ai-toolkit-setup'
    and l.lesson_number = '3.3'
    and m.course_id = c.id
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Removing real details and getting permission protects the people involved.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 1, 'What is an AI assistant?', '[{"key":"A","text":"A program you chat with that helps with questions and tasks"},{"key":"B","text":"A type of keyboard"},{"key":"C","text":"A kind of Wi-Fi router"},{"key":"D","text":"A video game console"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'An AI assistant answers questions and helps with tasks in plain language.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 2, 'What is the safest way to open ChatGPT?', '[{"key":"A","text":"Type chatgpt.com yourself in the address bar"},{"key":"B","text":"Click a link in an unknown message"},{"key":"C","text":"Download a free cracked app"},{"key":"D","text":"Use any site with ChatGPT in the name"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Typing the official address avoids fake copies of the site.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 3, 'Which company makes Claude?', '[{"key":"A","text":"Anthropic"},{"key":"B","text":"Google"},{"key":"C","text":"Microsoft"},{"key":"D","text":"Meta"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Claude is made by Anthropic.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 4, 'Which web address opens Gemini?', '[{"key":"A","text":"gemini.google.com"},{"key":"B","text":"claude.ai"},{"key":"C","text":"chatgpt.com"},{"key":"D","text":"mail.google.com"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'gemini.google.com is Google''s official address for Gemini.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 5, 'What does a verification code do?', '[{"key":"A","text":"Proves you own the email or phone number"},{"key":"B","text":"Makes the AI smarter"},{"key":"C","text":"Pays for your plan"},{"key":"D","text":"Speeds up the internet"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'The code is sent to you so the service knows it is really you.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 6, 'Why is it helpful to bookmark your AI tools?', '[{"key":"A","text":"You always reach the real website"},{"key":"B","text":"It makes the tools free for ever"},{"key":"C","text":"It stops hallucinations"},{"key":"D","text":"It deletes old chats"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Bookmarks take you straight to the correct address and protect you from fake sites.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 7, 'What is a prompt?', '[{"key":"A","text":"The instruction or question you type to an AI"},{"key":"B","text":"A computer virus"},{"key":"C","text":"An AI''s reply"},{"key":"D","text":"A type of password"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A prompt is what you type to tell the AI what you want.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 8, 'Which prompt is the clearest?', '[{"key":"A","text":"Write a friendly 3-sentence message to my landlord asking for a repair date next week"},{"key":"B","text":"Landlord"},{"key":"C","text":"Do my message"},{"key":"D","text":"Write something"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'It names the task, the tone, the length, the person and the goal.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 9, 'What does giving the AI a role mean?', '[{"key":"A","text":"Asking it to act as someone, like a teacher or career coach"},{"key":"B","text":"Hiring the AI"},{"key":"C","text":"Changing your name"},{"key":"D","text":"Logging out"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A role helps shape the style and depth of the answer.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 10, 'An answer is too long and too advanced. What is the best next step?', '[{"key":"A","text":"Reply in the same chat and ask for a shorter, simpler version"},{"key":"B","text":"Close the browser and give up"},{"key":"C","text":"Delete your account"},{"key":"D","text":"Ask the AI to repeat itself louder"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Follow-up instructions are the easiest way to improve an answer.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 11, 'What happens when you start a brand new chat?', '[{"key":"A","text":"The AI starts fresh and does not know your earlier chats unless memory is on"},{"key":"B","text":"The AI knows every word you ever typed"},{"key":"C","text":"Your account is deleted"},{"key":"D","text":"The AI shuts down"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A new chat begins without the earlier conversation unless a memory feature is switched on.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 12, 'What is a hallucination?', '[{"key":"A","text":"A false answer that sounds confident"},{"key":"B","text":"A very fast reply"},{"key":"C","text":"A password error"},{"key":"D","text":"A picture on the screen"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'A hallucination is an AI making up information while sounding sure.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 13, 'Why do AI assistants sometimes make things up?', '[{"key":"A","text":"They predict likely words and do not check facts"},{"key":"B","text":"They always look up every fact"},{"key":"C","text":"They are broken"},{"key":"D","text":"They copy your computer"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'They generate text from patterns, with no built-in fact check.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 14, 'Which of these is most important to double-check?', '[{"key":"A","text":"Exact numbers, dates, names and links"},{"key":"B","text":"Greetings"},{"key":"C","text":"Rhymes"},{"key":"D","text":"Emoji"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'These are the details AI most often gets wrong.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 15, 'The AI gives you a link as a source but the page does not exist. What should you do?', '[{"key":"A","text":"Do not rely on that source, because it may be invented"},{"key":"B","text":"Share it anyway"},{"key":"C","text":"Pay for the page"},{"key":"D","text":"Ignore all other sources"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'AI can invent sources, so always open them and check they are real.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 16, 'For health, legal and money questions, what is the best use of AI?', '[{"key":"A","text":"Understand the topic and prepare questions, then speak to a qualified person"},{"key":"B","text":"Replace the professional completely"},{"key":"C","text":"Follow the answer without checking"},{"key":"D","text":"Share the answer as fact"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'High-stakes matters need a qualified human to confirm.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 17, 'Which of these should you never type into an AI assistant?', '[{"key":"A","text":"Your OTP code"},{"key":"B","text":"A recipe question"},{"key":"C","text":"A request to shorten a paragraph"},{"key":"D","text":"A request to explain a word"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'OTP codes give access to your accounts and must stay secret.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 18, 'What is a safe way to use a client''s private document with an AI?', '[{"key":"A","text":"Get permission and replace real names and numbers with made-up ones"},{"key":"B","text":"Paste everything as it is"},{"key":"C","text":"Post it online"},{"key":"D","text":"Send it to friends"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Removing real details and getting permission protects other people.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 19, 'Where can you usually find options about how your chats are used?', '[{"key":"A","text":"In Settings, under names like Data controls, Privacy or Activity"},{"key":"B","text":"In the Recycle Bin"},{"key":"C","text":"On the keyboard"},{"key":"D","text":"In the taskbar clock"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Privacy options live in an AI tool''s settings. The exact names change over time, so look for these words.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


with inserted_question as (
  insert into public.assessment_questions (
    assessment_id, question_number, prompt, options
  )
  select a.id, 20, 'What should you do after using an AI on a shared computer or in a cyber cafe?', '[{"key":"A","text":"Sign out and do not save your password"},{"key":"B","text":"Leave the account open"},{"key":"C","text":"Save the password in the browser"},{"key":"D","text":"Tell the next person your password"}]'::jsonb
  from public.assessments a
  join public.courses c on c.id = a.course_id
  and a.assessment_type = 'final_assessment' and a.lesson_id is null
  where c.slug = 'ai-toolkit-setup'
  on conflict (assessment_id, question_number) do update
  set prompt = excluded.prompt,
      options = excluded.options
  returning id
)
insert into public.assessment_answer_keys (question_id, correct_option_key, explanation)
select id, 'A', 'Signing out and not saving passwords stops the next person from using your account.'
from inserted_question
on conflict (question_id) do update
set correct_option_key = excluded.correct_option_key,
    explanation = excluded.explanation;


do $$
declare
  v_courses integer;
  v_modules integer;
  v_lessons integer;
  v_assessments integer;
  v_questions integer;
  v_answer_keys integer;
begin
  select count(*) into v_courses
  from public.courses
  where slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
    and status = 'published';
  if v_courses <> 2 then
    raise exception 'S1/S2 seed validation failed: expected 2 published courses, found %', v_courses;
  end if;

  select count(*) into v_modules
  from public.course_modules m
  join public.courses c on c.id = m.course_id
  where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
    and m.status = 'published';
  if v_modules <> 9 then
    raise exception 'S1/S2 seed validation failed: expected 9 published modules, found %', v_modules;
  end if;

  select count(*) into v_lessons
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  join public.courses c on c.id = m.course_id
  where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
    and l.status = 'published';
  if v_lessons <> 22 then
    raise exception 'S1/S2 seed validation failed: expected 22 published lessons, found %', v_lessons;
  end if;

  select count(*) into v_assessments
  from public.assessments a
  join public.courses c on c.id = a.course_id
  where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
    and a.status = 'published';
  if v_assessments <> 24 then
    raise exception 'S1/S2 seed validation failed: expected 24 published assessments, found %', v_assessments;
  end if;

  select count(*) into v_questions
  from public.assessment_questions q
  join public.assessments a on a.id = q.assessment_id
  join public.courses c on c.id = a.course_id
  where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup');
  if v_questions <> 84 then
    raise exception 'S1/S2 seed validation failed: expected 84 questions, found %', v_questions;
  end if;

  select count(*) into v_answer_keys
  from public.assessment_answer_keys k
  join public.assessment_questions q on q.id = k.question_id
  join public.assessments a on a.id = q.assessment_id
  join public.courses c on c.id = a.course_id
  where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup');
  if v_answer_keys <> 84 then
    raise exception 'S1/S2 seed validation failed: expected 84 protected answer keys, found %', v_answer_keys;
  end if;

  if exists (
    select 1
    from public.assessments a
    join public.lessons l on l.id = a.lesson_id
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = a.course_id
    where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
      and a.assessment_type = 'lesson_quiz'
      and (
        select count(*) from public.assessment_questions q
        where q.assessment_id = a.id
      ) <> 2
  ) then
    raise exception 'S1/S2 seed validation failed: every lesson quiz must contain exactly 2 questions';
  end if;

  if exists (
    select 1
    from public.assessments a
    join public.courses c on c.id = a.course_id
    where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
      and a.assessment_type = 'final_assessment'
      and (
        select count(*) from public.assessment_questions q
        where q.assessment_id = a.id
      ) <> 20
  ) then
    raise exception 'S1/S2 seed validation failed: every final assessment must contain exactly 20 questions';
  end if;

  if exists (
    select 1
    from public.assessment_questions q
    join public.assessment_answer_keys k on k.question_id = q.id
    join public.assessments a on a.id = q.assessment_id
    join public.courses c on c.id = a.course_id
    where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
      and not exists (
        select 1
        from jsonb_array_elements(q.options) opt
        where opt->>'key' = k.correct_option_key
      )
  ) then
    raise exception 'S1/S2 seed validation failed: an answer key does not match one of its question options';
  end if;
end;
$$;

commit;

-- Expected import totals:
-- 2 published courses
-- 9 published modules
-- 22 published lessons
-- 22 lesson-quiz assessments + 2 final assessments
-- 44 lesson-quiz questions + 40 final-assessment questions
-- Total: 84 questions with answer keys stored separately.

-- Verification summary after the transaction commits.
select
  c.slug,
  c.status,
  count(distinct m.id) as published_modules,
  count(distinct l.id) as published_lessons
from public.courses c
left join public.course_modules m
  on m.course_id = c.id and m.status = 'published'
left join public.lessons l
  on l.module_id = m.id and l.status = 'published'
where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
group by c.id, c.slug, c.status
order by c.slug;

select
  c.slug,
  a.assessment_type,
  count(distinct a.id) as assessments,
  count(distinct q.id) as questions,
  count(distinct k.question_id) as protected_answer_keys
from public.courses c
join public.assessments a on a.course_id = c.id
left join public.assessment_questions q on q.assessment_id = a.id
left join public.assessment_answer_keys k on k.question_id = q.id
where c.slug in ('computer-and-internet-readiness', 'ai-toolkit-setup')
group by c.slug, a.assessment_type
order by c.slug, a.assessment_type;
