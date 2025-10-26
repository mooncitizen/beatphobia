-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================
-- OPTIONAL: Run this to populate your database with sample posts
-- You can skip this and create posts from the app instead
-- =====================================================

-- NOTE: Replace 'YOUR_USER_ID_HERE' with an actual user ID from your auth.users table
-- You can find your user ID by running: SELECT id FROM auth.users LIMIT 1;

-- First, ensure your profile has a username (REQUIRED!)
-- UPDATE profile SET username = 'testuser' WHERE id = 'YOUR_USER_ID_HERE';

-- Sample posts
INSERT INTO community_posts (user_id, title, content, category, tags, likes_count, comments_count) VALUES
(
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    '3 months progress - I can finally go to the grocery store!',
    'Just wanted to share my journey. Three months ago I couldn''t leave my house without severe panic. Today I went to the grocery store during peak hours and felt completely fine! Using the breathing techniques from this app really helped. For anyone struggling - it gets better!',
    'success',
    ARRAY['agoraphobia', 'progress', 'exposure'],
    47,
    12
),
(
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    'How do you handle setbacks?',
    'I had been doing so well for weeks, but yesterday I had a major panic attack. How do you all cope with setbacks and not feel like you''re back at square one? Any advice would be appreciated.',
    'question',
    ARRAY['setbacks', 'panic', 'advice'],
    23,
    31
),
(
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    'Struggling with social events',
    'I have a friend''s wedding coming up and I''m terrified. The venue is 2 hours away, it''s indoors with lots of people. Any tips for preparing? I really want to be there for my friend but I''m so anxious about it.',
    'support',
    ARRAY['social anxiety', 'events', 'help needed'],
    18,
    24
),
(
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    'The role of medication in recovery',
    'I''m curious about everyone''s experience with medication. Has it helped? What about side effects? My therapist suggested trying medication alongside CBT and I''m trying to make an informed decision.',
    'discussion',
    ARRAY['medication', 'treatment', 'CBT'],
    56,
    43
),
(
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    'First flight in 5 years!',
    'I did it! After 5 years of avoiding planes, I just completed a 3-hour flight. Used all the breathing techniques and grounding exercises. The panic scale tracker really helped me see my progress. So proud of myself!',
    'success',
    ARRAY['flying', 'victory', 'breathing'],
    89,
    18
);

-- You can add sample comments after posts are created:
-- First, get the post IDs: SELECT id, title FROM community_posts;
-- Then insert comments using those IDs

-- Example (replace POST_ID_HERE with actual post ID):
-- INSERT INTO community_comments (post_id, user_id, content) VALUES
-- ('POST_ID_HERE', 'YOUR_USER_ID_HERE', 'This is so inspiring! Thank you for sharing your story.');

