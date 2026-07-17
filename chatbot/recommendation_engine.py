import random
from typing import Optional, List, Dict

class RecommendationEngine:
    """Provides recommendations for movies, books, music, and more."""

    def __init__(self):
        self.user_preferences = {
            "movies": [],
            "books": [],
            "music": [],
            "games": [],
            "food": []
        }
        self.database = self._build_database()

    def _build_database(self) -> Dict:
        """Build the recommendation database."""
        return {
            "movies": {
                "action": [
                    {"title": "The Dark Knight", "year": 2008, "rating": 9.0, "description": "Batman faces the Joker, a criminal mastermind who plunges Gotham into anarchy."},
                    {"title": "Mad Max: Fury Road", "year": 2015, "rating": 8.1, "description": "In a post-apocalyptic wasteland, a woman rebels against a tyrannical ruler."},
                    {"title": "John Wick", "year": 2014, "rating": 7.4, "description": "An ex-hitman comes out of retirement to track down the gangsters that killed his dog."},
                    {"title": "Avengers: Endgame", "year": 2019, "rating": 8.4, "description": "The Avengers assemble once more to reverse Thanos' actions and restore balance."},
                    {"title": "Gladiator", "year": 2000, "rating": 8.5, "description": "A former Roman General sets out to exact vengeance against the emperor who murdered his family."}
                ],
                "comedy": [
                    {"title": "The Grand Budapest Hotel", "year": 2014, "rating": 8.1, "description": "A writer encounters the owner of an aging high-class hotel, who tells him of his early years."},
                    {"title": "Superbad", "year": 2007, "rating": 7.6, "description": "Two co-dependent high school seniors are forced to deal with separation anxiety after their plan to stage a party goes awry."},
                    {"title": "The Office", "year": 2005, "rating": 9.0, "description": "A mockumentary on a group of typical office workers."},
                    {"title": "Brooklyn Nine-Nine", "year": 2013, "rating": 8.4, "description": "Jake Peralta, a talented but immature NYPD detective, must learn to follow rules."},
                    {"title": "Parks and Recreation", "year": 2009, "rating": 8.6, "description": "The absurd antics of an Indiana town's public officials as they pursue their secondary jobs."}
                ],
                "drama": [
                    {"title": "The Shawshank Redemption", "year": 1994, "rating": 9.3, "description": "Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency."},
                    {"title": "Forrest Gump", "year": 1994, "rating": 8.8, "description": "The presidencies of Kennedy and Johnson, the Vietnam War, and other historical events unfold from the perspective of an Alabama man."},
                    {"title": "The Godfather", "year": 1972, "rating": 9.2, "description": "The aging patriarch of an organized crime dynasty transfers control of his empire to his reluctant son."},
                    {"title": "Inception", "year": 2010, "rating": 8.8, "description": "A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea."},
                    {"title": "The Matrix", "year": 1999, "rating": 8.7, "description": "A computer hacker learns from mysterious rebels about the true nature of his reality."}
                ],
                "scifi": [
                    {"title": "Interstellar", "year": 2014, "rating": 8.6, "description": "A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival."},
                    {"title": "Blade Runner 2049", "year": 2017, "rating": 8.0, "description": "Young Blade Runner K's discovery of a long-buried secret leads him on a quest."},
                    {"title": "The Martian", "year": 2015, "rating": 8.0, "description": "An astronaut becomes stranded on Mars after his team assume him dead and must rely on his ingenuity to survive."},
                    {"title": "Arrival", "year": 2016, "rating": 7.9, "description": "A linguist works with the military to communicate with alien lifeforms after twelve mysterious spacecraft appear."},
                    {"title": "Ex Machina", "year": 2014, "rating": 7.7, "description": "A programmer is selected to participate in a groundbreaking experiment in synthetic intelligence."}
                ],
                "horror": [
                    {"title": "The Conjuring", "year": 2013, "rating": 7.5, "description": "Paranormal investigators Ed and Lorraine Warren work to help a family terrorized by a dark presence."},
                    {"title": "Get Out", "year": 2017, "rating": 7.7, "description": "A young African-American visits his white girlfriend's parents for the weekend, where his simmering uneasiness about their reception of him."},
                    {"title": "Hereditary", "year": 2018, "rating": 7.3, "description": "A grieving family is haunted by tragic and disturbing occurrences."},
                    {"title": "A Quiet Place", "year": 2018, "rating": 7.5, "description": "In a post-apocalyptic world, a family is forced to live in silence while hiding from monsters."},
                    {"title": "The Babadook", "year": 2014, "rating": 6.8, "description": "A single mother, plagued by the violent death of her husband, battles with her son's dark night of the soul."}
                ]
            },
            "books": {
                "fiction": [
                    {"title": "To Kill a Mockingbird", "author": "Harper Lee", "year": 1960, "rating": 4.3, "description": "The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it."},
                    {"title": "1984", "author": "George Orwell", "year": 1949, "rating": 4.2, "description": "A dystopian novel set in a totalitarian society ruled by Big Brother."},
                    {"title": "Pride and Prejudice", "author": "Jane Austen", "year": 1813, "rating": 4.3, "description": "The story follows the main character, Elizabeth Bennet, as she deals with issues of manners and marriage."},
                    {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "year": 1925, "rating": 3.9, "description": "A story of the mysteriously wealthy Jay Gatsby and his love for the beautiful Daisy Buchanan."},
                    {"title": "One Hundred Years of Solitude", "author": "Gabriel García Márquez", "year": 1967, "rating": 4.1, "description": "The multi-generational story of the Buendía family, whose patriarch José Arcadio founded the fictitious town."}
                ],
                "nonfiction": [
                    {"title": "Sapiens: A Brief History of Humankind", "author": "Yuval Noah Harari", "year": 2011, "rating": 4.4, "description": "A groundbreaking narrative of humanity's creation and evolution."},
                    {"title": "Thinking, Fast and Slow", "author": "Daniel Kahneman", "year": 2011, "rating": 4.1, "description": "A groundbreaking tour of the mind that explains the two systems that drive the way we think."},
                    {"title": "The Art of War", "author": "Sun Tzu", "year": -500, "rating": 4.2, "description": "An ancient Chinese military treatise dating from the Late Spring and Autumn Period."},
                    {"title": "Atomic Habits", "author": "James Clear", "year": 2018, "rating": 4.4, "description": "An easy and proven way to build good habits and break bad ones."},
                    {"title": "The 48 Laws of Power", "author": "Robert Greene", "year": 1998, "rating": 4.2, "description": "Distills 3,000 years of the history of power into 48 essential laws."}
                ],
                "scifi": [
                    {"title": "Dune", "author": "Frank Herbert", "year": 1965, "rating": 4.3, "description": "Set on the desert planet Arrakis, it is the story of the boy Paul Atreides, heir to a noble family."},
                    {"title": "Neuromancer", "author": "William Gibson", "year": 1984, "rating": 3.9, "description": "The novel that launched the cyberpunk generation."},
                    {"title": "The Hitchhiker's Guide to the Galaxy", "author": "Douglas Adams", "year": 1979, "rating": 4.2, "description": "Seconds before the Earth is demolished to make way for a galactic freeway, Arthur Dent is plucked off the planet."},
                    {"title": "Foundation", "author": "Isaac Asimov", "year": 1951, "rating": 4.2, "description": "The story of the fall of the Galactic Empire and the efforts of a group of scientists to preserve knowledge."},
                    {"title": "Ender's Game", "author": "Orson Scott Card", "year": 1985, "rating": 4.3, "description": "Andrew 'Ender' Wiggin thinks he is playing computer simulated war games; he is, in fact, engaged in something far more serious."}
                ],
                "mystery": [
                    {"title": "The Hound of the Baskervilles", "author": "Arthur Conan Doyle", "year": 1902, "rating": 4.1, "description": "Sherlock Holmes investigates the legend of a demonic hound haunting the Baskerville family."},
                    {"title": "Gone Girl", "author": "Gillian Flynn", "year": 2012, "rating": 4.0, "description": "On a warm summer morning in North Carthage, Missouri, it is Nick and Amy Dunne's fifth wedding anniversary."},
                    {"title": "The Girl with the Dragon Tattoo", "author": "Stieg Larsson", "year": 2005, "rating": 4.1, "description": "A spellbinding amalgam of murder mystery, family saga, love story, and financial intrigue."},
                    {"title": "Big Little Lies", "author": "Liane Moriarty", "year": 2014, "rating": 4.1, "description": "The seemingly perfect life of three mothers unravels in the weeks leading up to a school fundraiser."},
                    {"title": "The Silent Patient", "author": "Alex Michaelides", "year": 2019, "rating": 4.1, "description": "Alicia Berenson's life is seemingly perfect until one evening she shoots her husband five times."}
                ]
            },
            "music": {
                "rock": [
                    {"artist": "Led Zeppelin", "album": "Led Zeppelin IV", "year": 1971, "rating": 4.5, "description": "Features 'Stairway to Heaven' and is considered one of the greatest rock albums."},
                    {"artist": "Pink Floyd", "album": "The Dark Side of the Moon", "year": 1973, "rating": 4.5, "description": "A concept album exploring themes of conflict, greed, time, and mental illness."},
                    {"artist": "Nirvana", "album": "Nevermind", "year": 1991, "rating": 4.4, "description": "The album that brought grunge into the mainstream with 'Smells Like Teen Spirit'."},
                    {"artist": "The Beatles", "album": "Abbey Road", "year": 1969, "rating": 4.5, "description": "The final studio album recorded by the Beatles."},
                    {"artist": "Queen", "album": "A Night at the Opera", "year": 1975, "rating": 4.4, "description": "Features 'Bohemian Rhapsody' and showcases Queen's eclectic style."}
                ],
                "pop": [
                    {"artist": "Michael Jackson", "album": "Thriller", "year": 1982, "rating": 4.5, "description": "The best-selling album of all time with iconic tracks."},
                    {"artist": "Taylor Swift", "album": "1989", "year": 2014, "rating": 4.2, "description": "A pop album featuring hits like 'Shake It Off' and 'Blank Space'."},
                    {"artist": "Adele", "album": "21", "year": 2011, "rating": 4.4, "description": "Features 'Rolling in the Deep' and 'Someone Like You'."},
                    {"artist": "Ed Sheeran", "album": "÷ (Divide)", "year": 2017, "rating": 4.0, "description": "Features 'Shape of You' and 'Castle on the Hill'."},
                    {"artist": "Billie Eilish", "album": "When We All Fall Asleep, Where Do We Go?", "year": 2019, "rating": 4.1, "description": "A debut album that won Album of the Year at the Grammys."}
                ],
                "jazz": [
                    {"artist": "Miles Davis", "album": "Kind of Blue", "year": 1959, "rating": 4.5, "description": "The best-selling jazz album of all time."},
                    {"artist": "John Coltrane", "album": "A Love Supreme", "year": 1965, "rating": 4.5, "description": "A deeply spiritual and influential jazz album."},
                    {"artist": "Dave Brubeck", "album": "Time Out", "year": 1959, "rating": 4.3, "description": "Features the iconic 'Take Five'."},
                    {"artist": "Thelonious Monk", "album": "Brilliant Corners", "year": 1957, "rating": 4.2, "description": "A challenging and innovative jazz album."},
                    {"artist": "Bill Evans", "album": "Waltz for Debby", "year": 1962, "rating": 4.4, "description": "A beautiful and intimate piano trio album."}
                ],
                "classical": [
                    {"artist": "Ludwig van Beethoven", "album": "Symphony No. 9", "year": 1824, "rating": 4.5, "description": "The final complete symphony by Beethoven, featuring the famous 'Ode to Joy'."},
                    {"artist": "Johann Sebastian Bach", "album": "The Well-Tempered Clavier", "year": 1722, "rating": 4.4, "description": "A collection of solo keyboard music by Bach."},
                    {"artist": "Wolfgang Amadeus Mozart", "album": "Requiem", "year": 1791, "rating": 4.5, "description": "Mozart's final composition, left unfinished at his death."},
                    {"artist": "Claude Debussy", "album": "Clair de Lune", "year": 1905, "rating": 4.3, "description": "A collection of piano pieces including the famous 'Clair de Lune'."},
                    {"artist": "Frédéric Chopin", "album": "Nocturnes", "year": 1832, "rating": 4.4, "description": "A collection of 21 nocturnes for solo piano."}
                ],
                "electronic": [
                    {"artist": "Daft Punk", "album": "Random Access Memories", "year": 2013, "rating": 4.3, "description": "Features 'Get Lucky' and won Album of the Year at the Grammys."},
                    {"artist": "Kraftwerk", "album": "Trans-Europe Express", "year": 1977, "rating": 4.2, "description": "A pioneering electronic album that influenced generations of musicians."},
                    {"artist": "Aphex Twin", "album": "Selected Ambient Works 85-92", "year": 1992, "rating": 4.3, "description": "A landmark ambient electronic album."},
                    {"artist": "Radiohead", "album": "OK Computer", "year": 1997, "rating": 4.5, "description": "While primarily rock, it incorporates electronic elements and is considered a masterpiece."},
                    {"artist": "The Prodigy", "album": "The Fat of the Land", "year": 1997, "rating": 4.1, "description": "Features 'Firestarter' and 'Breathe'."}
                ]
            },
            "games": {
                "rpg": [
                    {"title": "The Witcher 3: Wild Hunt", "year": 2015, "rating": 9.3, "description": "A story-driven open world RPG set in a visually stunning fantasy universe."},
                    {"title": "The Elder Scrolls V: Skyrim", "year": 2011, "rating": 9.4, "description": "An open-world action RPG set in the province of Skyrim."},
                    {"title": "Baldur's Gate 3", "year": 2023, "rating": 9.6, "description": "A rich, narrative-driven RPG set in the Dungeons & Dragons universe."},
                    {"title": "Red Dead Redemption 2", "year": 2018, "rating": 9.7, "description": "An epic tale of life in America's unforgiving heartland."},
                    {"title": "Final Fantasy VII Remake", "year": 2020, "rating": 8.7, "description": "A reimagining of the classic RPG with modern graphics and gameplay."}
                ],
                "action": [
                    {"title": "The Legend of Zelda: Breath of the Wild", "year": 2017, "rating": 9.7, "description": "An open-world action-adventure set in the vast fields of Hyrule."},
                    {"title": "God of War", "year": 2018, "rating": 9.4, "description": "A father-son journey through Norse mythology."},
                    {"title": "Sekiro: Shadows Die Twice", "year": 2019, "rating": 9.0, "description": "A fast-paced action game set in a mythical Japan."},
                    {"title": "Devil May Cry 5", "year": 2019, "rating": 8.8, "description": "A stylish action game with three playable characters."},
                    {"title": "Hades", "year": 2020, "rating": 9.3, "description": "A roguelike dungeon crawler that won numerous Game of the Year awards."}
                ],
                "puzzle": [
                    {"title": "Portal 2", "year": 2011, "rating": 9.5, "description": "A first-person puzzle platformer with an engaging story."},
                    {"title": "The Witness", "year": 2016, "rating": 8.7, "description": "An open-world puzzle game set on a mysterious island."},
                    {"title": "Tetris Effect", "year": 2018, "rating": 8.7, "description": "A mesmerizing evolution of the classic Tetris formula."},
                    {"title": "Baba Is You", "year": 2019, "rating": 8.9, "description": "A puzzle game where you change the rules to solve puzzles."},
                    {"title": "Return of the Obra Dinn", "year": 2018, "rating": 9.0, "description": "A mystery game where you reconstruct the fate of a lost ship."}
                ],
                "strategy": [
                    {"title": "Civilization VI", "year": 2016, "rating": 8.8, "description": "A turn-based strategy game where you build an empire to stand the test of time."},
                    {"title": "XCOM 2", "year": 2016, "rating": 8.8, "description": "A tactical turn-based game about fighting back against an alien occupation."},
                    {"title": "Stardew Valley", "year": 2016, "rating": 8.8, "description": "A farming simulation game with RPG elements."},
                    {"title": "Into the Breach", "year": 2018, "rating": 9.0, "description": "A tactical roguelike where you control powerful mechs."},
                    {"title": "Disco Elysium", "year": 2019, "rating": 9.1, "description": "A revolutionary RPG with deep dialogue and investigation systems."}
                ],
                "horror": [
                    {"title": "Resident Evil 2 Remake", "year": 2019, "rating": 9.1, "description": "A survival horror game that reimagines the classic."},
                    {"title": "Alien: Isolation", "year": 2014, "rating": 8.1, "description": "A survival horror game set in the Alien universe."},
                    {"title": "Layers of Fear", "year": 2016, "rating": 7.5, "description": "A psychological horror game about a painter's descent into madness."},
                    {"title": "Outlast", "year": 2013, "rating": 7.9, "description": "A first-person survival horror game set in an abandoned asylum."},
                    {"title": "Amnesia: The Dark Descent", "year": 2010, "rating": 8.5, "description": "A first-person survival horror game that redefined the genre."}
                ]
            },
            "food": {
                "italian": [
                    {"name": "Spaghetti Carbonara", "description": "Classic pasta with eggs, cheese, pancetta, and pepper.", "difficulty": "Medium"},
                    {"name": "Margherita Pizza", "description": "Simple pizza with tomatoes, mozzarella, and basil.", "difficulty": "Easy"},
                    {"name": "Risotto", "description": "Creamy Italian rice dish cooked with broth.", "difficulty": "Medium"},
                    {"name": "Tiramisu", "description": "Coffee-flavored Italian dessert with mascarpone cheese.", "difficulty": "Medium"},
                    {"name": "Penne Arrabbiata", "description": "Pasta in spicy tomato sauce.", "difficulty": "Easy"}
                ],
                "asian": [
                    {"name": "Pad Thai", "description": "Thai stir-fried noodles with shrimp, tofu, and peanuts.", "difficulty": "Medium"},
                    {"name": "Sushi", "description": "Japanese vinegared rice with seafood and vegetables.", "difficulty": "Hard"},
                    {"name": "Chicken Tikka Masala", "description": "Indian spiced chicken in creamy tomato sauce.", "difficulty": "Medium"},
                    {"name": "Kung Pao Chicken", "description": "Chinese stir-fried chicken with peanuts and vegetables.", "difficulty": "Medium"},
                    {"name": "Pho", "description": "Vietnamese noodle soup with herbs and meat.", "difficulty": "Hard"}
                ],
                "mexican": [
                    {"name": "Tacos", "description": "Mexican tortillas filled with meat, vegetables, and salsa.", "difficulty": "Easy"},
                    {"name": "Guacamole", "description": "Creamy avocado dip with lime and cilantro.", "difficulty": "Easy"},
                    {"name": "Enchiladas", "description": "Rolled tortillas filled with meat and covered in chili sauce.", "difficulty": "Medium"},
                    {"name": "Churros", "description": "Fried dough pastry coated in cinnamon sugar.", "difficulty": "Medium"},
                    {"name": "Quesadillas", "description": "Grilled tortilla filled with cheese and other ingredients.", "difficulty": "Easy"}
                ],
                "desserts": [
                    {"name": "Chocolate Cake", "description": "Rich and moist chocolate layer cake.", "difficulty": "Medium"},
                    {"name": "Cheesecake", "description": "Creamy baked cheesecake with graham cracker crust.", "difficulty": "Medium"},
                    {"name": "Apple Pie", "description": "Classic American apple pie with flaky crust.", "difficulty": "Medium"},
                    {"name": "Ice Cream Sundae", "description": "Ice cream with toppings like chocolate sauce, nuts, and whipped cream.", "difficulty": "Easy"},
                    {"name": "Crème Brûlée", "description": "French custard dessert with a caramelized sugar top.", "difficulty": "Hard"}
                ],
                "healthy": [
                    {"name": "Quinoa Bowl", "description": "Nutritious bowl with quinoa, vegetables, and protein.", "difficulty": "Easy"},
                    {"name": "Grilled Salmon", "description": "Healthy omega-3 rich fish with herbs.", "difficulty": "Medium"},
                    {"name": "Smoothie Bowl", "description": "Blended fruits topped with granola and berries.", "difficulty": "Easy"},
                    {"name": "Mediterranean Salad", "description": "Fresh salad with olive oil, feta, and vegetables.", "difficulty": "Easy"},
                    {"name": "Stuffed Bell Peppers", "description": "Bell peppers filled with rice, vegetables, and lean protein.", "difficulty": "Medium"}
                ]
            }
        }

    def is_recommendation_request(self, text: str) -> bool:
        """Check if the input is a recommendation request."""
        keywords = [
            'recommend', 'suggestion', 'suggest', 'what should i watch',
            'what should i read', 'what should i play', 'what should i listen',
            'what should i eat', 'what should i cook', 'give me some',
            'give me', 'i want', 'i need', 'looking for', 'need a',
            'movie', 'book', 'music', 'song', 'album', 'game', 'food',
            'restaurant', 'recipe', 'show', 'series', 'anime', 'manga'
        ]
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in keywords)

    def detect_category(self, text: str) -> tuple:
        """Detect what category the user wants recommendations for."""
        text_lower = text.lower()
        
        genre_keywords = {
            "action": ['action', 'exciting', 'thrilling', 'adventure'],
            "comedy": ['funny', 'comedy', 'humor', 'laugh'],
            "drama": ['drama', 'emotional', 'serious', 'deep'],
            "scifi": ['sci-fi', 'science fiction', 'futuristic', 'space'],
            "horror": ['horror', 'scary', 'spooky', 'terrifying', 'frightening'],
            "fiction": ['fiction', 'story', 'novel'],
            "nonfiction": ['non-fiction', 'nonfiction', 'true story', 'real', 'educational'],
            "mystery": ['mystery', 'detective', 'crime', 'thriller'],
            "rock": ['rock', 'classic rock', 'guitar'],
            "pop": ['pop', 'popular', 'top hits'],
            "jazz": ['jazz', 'smooth', 'saxophone'],
            "classical": ['classical', 'orchestra', 'piano', 'symphony'],
            "electronic": ['electronic', 'edm', 'dance', 'techno'],
            "rpg": ['rpg', 'role playing', 'adventure game'],
            "puzzle": ['puzzle', 'brain teaser', 'thinking'],
            "strategy": ['strategy', 'strategy game', 'tactical'],
            "italian": ['italian', 'pasta', 'pizza'],
            "asian": ['asian', 'chinese', 'japanese', 'thai', 'indian', 'korean', 'vietnamese'],
            "mexican": ['mexican', 'taco', 'burrito'],
            "desserts": ['dessert', 'sweet', 'cake', 'pastry'],
            "healthy": ['healthy', 'salad', 'low calorie', 'diet']
        }
        
        category = None
        genre = None
        
        if any(word in text_lower for word in ['movie', 'film', 'watch', 'show', 'series', 'cinema', 'netflix']):
            category = 'movies'
        elif any(word in text_lower for word in ['book', 'read', 'novel', 'author', 'literature']):
            category = 'books'
        elif any(word in text_lower for word in ['music', 'song', 'album', 'artist', 'listen', 'playlist', 'band']):
            category = 'music'
        elif any(word in text_lower for word in ['game', 'play', 'gaming', 'video game']):
            category = 'games'
        elif any(word in text_lower for word in ['food', 'eat', 'cook', 'recipe', 'restaurant', 'meal', 'dish', 'cuisine']):
            category = 'food'
        
        for g, keywords in genre_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                genre = g
                break
        
        return category, genre

    def get_recommendations(self, text: str, count: int = 3) -> str:
        """Get recommendations based on user input."""
        category, genre = self.detect_category(text)
        
        if not category:
            return "I'd be happy to recommend something! What are you looking for? (movies, books, music, games, or food)"
        
        items = []
        available_genres = list(self.database[category].keys())
        
        if genre and genre in self.database[category]:
            items = self.database[category][genre]
            random.shuffle(items)
            items = items[:count]
            genre_label = genre.title()
        else:
            random_genre = random.choice(available_genres)
            items = self.database[category][random_genre]
            random.shuffle(items)
            items = items[:count]
            genre_label = random_genre.title()
        
        if not items:
            return f"I don't have any {category} recommendations right now. Try asking for something else!"
        
        response = f"Here are my {category} recommendations ({genre_label}):\n\n"
        
        for i, item in enumerate(items, 1):
            if category == 'movies':
                response += f"{i}. **{item['title']}** ({item['year']}) - Rating: {item['rating']}/10\n"
                response += f"   {item['description']}\n\n"
            elif category == 'books':
                response += f"{i}. **{item['title']}** by {item['author']} ({item['year']}) - Rating: {item['rating']}/5\n"
                response += f"   {item['description']}\n\n"
            elif category == 'music':
                response += f"{i}. **{item['album']}** by {item['artist']} ({item['year']}) - Rating: {item['rating']}/5\n"
                response += f"   {item['description']}\n\n"
            elif category == 'games':
                response += f"{i}. **{item['title']}** ({item['year']}) - Rating: {item['rating']}/10\n"
                response += f"   {item['description']}\n\n"
            elif category == 'food':
                response += f"{i}. **{item['name']}** - Difficulty: {item['difficulty']}\n"
                response += f"   {item['description']}\n\n"
        
        response += "Would you like more recommendations or something different?"
        
        return response

    def add_preference(self, category: str, item: str):
        """Add a user preference."""
        if category in self.user_preferences:
            self.user_preferences[category].append(item)

    def get_personalized_recommendations(self, category: str, count: int = 3) -> str:
        """Get recommendations based on user preferences."""
        if category not in self.user_preferences:
            return f"I don't have preferences for {category} yet."
        
        if not self.user_preferences[category]:
            return f"Tell me what {category} you like, and I'll give you personalized recommendations!"
        
        response = f"Based on your preferences, here are some {category} you might enjoy:\n\n"
        
        return response
