import os
import re
from typing import Optional, Dict, List

class CodeGenerator:
    """Generates websites and mobile apps from descriptions."""

    def __init__(self):
        self.output_dir = "generated_projects"
        self.templates = self._build_templates()

    def _build_templates(self) -> Dict:
        """Build code templates for websites and apps."""
        return {
            "website": {
                "landing": self._landing_page_template(),
                "portfolio": self._portfolio_template(),
                "blog": self._blog_template(),
                "ecommerce": self._ecommerce_template(),
                "business": self._business_template(),
                "restaurant": self._restaurant_template(),
                "agency": self._agency_template(),
                "resume": self._resume_template(),
            },
            "mobile": {
                "react_native": self._react_native_template(),
                "flutter": self._flutter_template(),
            }
        }

    def is_code_request(self, text: str) -> bool:
        """Check if user wants to create code."""
        keywords = [
            'create website', 'build website', 'make website', 'generate website',
            'create app', 'build app', 'make app', 'generate app',
            'create mobile', 'build mobile', 'make mobile',
            'html', 'css', 'javascript', 'react native', 'flutter',
            'landing page', 'portfolio', 'blog site', 'ecommerce',
            'web page', 'webpage', 'site', 'design website',
            'write code', 'generate code', 'create code'
        ]
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in keywords)

    def detect_project_type(self, text: str) -> tuple:
        """Detect what type of project the user wants."""
        text_lower = text.lower()
        
        is_mobile = any(word in text_lower for word in ['mobile', 'app', 'react native', 'flutter', 'android', 'ios', 'phone'])
        
        if is_mobile:
            if 'flutter' in text_lower:
                return 'mobile', 'flutter'
            return 'mobile', 'react_native'
        
        website_types = {
            'landing': ['landing', 'landing page', 'single page', 'one page', 'coming soon'],
            'portfolio': ['portfolio', 'personal site', 'personal website', 'showcase'],
            'blog': ['blog', 'blog site', 'blogging', 'articles'],
            'ecommerce': ['ecommerce', 'e-commerce', 'shop', 'store', 'online store', 'shopping'],
            'business': ['business', 'corporate', 'company', 'enterprise'],
            'restaurant': ['restaurant', 'cafe', 'food', 'dining', 'menu'],
            'agency': ['agency', 'creative', 'design agency', 'marketing'],
            'resume': ['resume', 'cv', 'curriculum vitae', 'job application']
        }
        
        for site_type, keywords in website_types.items():
            if any(keyword in text_lower for keyword in keywords):
                return 'website', site_type
        
        return 'website', 'landing'

    def extract_details(self, text: str) -> Dict:
        """Extract project details from user input."""
        details = {
            "name": "",
            "description": "",
            "colors": [],
            "features": []
        }
        
        text_lower = text.lower()
        
        name_match = re.search(r'(?:called|named|title|name)\s+["\']?([^"\']+)["\']?', text_lower)
        if name_match:
            details["name"] = name_match.group(1).strip().title()
        
        if not details["name"]:
            if 'my' in text_lower:
                my_match = re.search(r'my\s+(\w+)', text_lower)
                if my_match:
                    details["name"] = my_match.group(1).title() + " Website"
            
            if not details["name"]:
                details["name"] = "My Project"
        
        color_match = re.search(r'(?:color|colour|theme)\s+(?:is\s+)?(\w+)', text_lower)
        if color_match:
            details["colors"].append(color_match.group(1))
        
        if 'dark' in text_lower:
            details["colors"].append("dark")
        elif 'light' in text_lower:
            details["colors"].append("light")
        
        return details

    def generate_website(self, site_type: str, details: Dict) -> str:
        """Generate a website project."""
        template = self.templates["website"].get(site_type, self.templates["website"]["landing"])
        
        name = details.get("name", "My Website")
        description = details.get("description", "A beautiful website")
        
        html_content = template["html"].replace("{name}", name).replace("{description}", description)
        
        css_content = template["css"]
        
        js_content = template.get("js", "")
        
        project_dir = os.path.join(self.output_dir, details.get("name", "website").lower().replace(" ", "_"))
        os.makedirs(project_dir, exist_ok=True)
        
        with open(os.path.join(project_dir, "index.html"), "w") as f:
            f.write(html_content)
        
        with open(os.path.join(project_dir, "styles.css"), "w") as f:
            f.write(css_content)
        
        if js_content:
            with open(os.path.join(project_dir, "script.js"), "w") as f:
                f.write(js_content)
        
        return project_dir

    def generate_mobile_app(self, app_type: str, details: Dict) -> str:
        """Generate a mobile app project."""
        template = self.templates["mobile"].get(app_type, self.templates["mobile"]["react_native"])
        
        project_dir = os.path.join(self.output_dir, details.get("name", "app").lower().replace(" ", "_"))
        os.makedirs(project_dir, exist_ok=True)
        
        for filename, content in template.items():
            file_content = content.replace("{name}", details.get("name", "MyApp"))
            
            with open(os.path.join(project_dir, filename), "w") as f:
                f.write(file_content)
        
        return project_dir

    def generate(self, text: str) -> str:
        """Main method to generate code based on user input."""
        project_type, project_subtype = self.detect_project_type(text)
        details = self.extract_details(text)
        
        if project_type == 'website':
            project_dir = self.generate_website(project_subtype, details)
            return self.format_website_response(project_dir, project_subtype, details)
        else:
            project_dir = self.generate_mobile_app(project_subtype, details)
            return self.format_mobile_response(project_dir, project_subtype, details)

    def format_website_response(self, project_dir: str, site_type: str, details: Dict) -> str:
        """Format the response for website generation."""
        response = f"""
╔══════════════════════════════════════════════════════════════╗
║                  Website Created Successfully!              ║
╠══════════════════════════════════════════════════════════════╣
║  Project Type: {site_type.title()} Website
║  Location: {project_dir}
║  Files Created:
║  • index.html - Main HTML file
║  • styles.css - Styling file
║  • script.js - JavaScript (if applicable)
║                                                             ║
║  To view: Open index.html in your browser                   ║
╚══════════════════════════════════════════════════════════════╝

Generated HTML preview (first 500 chars):
"""
        html_path = os.path.join(project_dir, "index.html")
        if os.path.exists(html_path):
            with open(html_path, "r") as f:
                content = f.read()[:500]
                response += f"```\n{content}\n...\n```\n"
        
        response += "\nWould you like me to modify anything or add more features?"
        return response

    def format_mobile_response(self, project_dir: str, app_type: str, details: Dict) -> str:
        """Format the response for mobile app generation."""
        framework = "React Native" if app_type == "react_native" else "Flutter"
        
        response = f"""
╔══════════════════════════════════════════════════════════════╗
║                Mobile App Created Successfully!             ║
╠══════════════════════════════════════════════════════════════╣
║  Framework: {framework}
║  Location: {project_dir}
║  Files Created:
║  • App.js / main.dart - Main app file
║  • package.json / pubspec.yaml - Dependencies
║  • README.md - Setup instructions
║                                                             ║
║  To run:                                                    ║
║  {framework}: Follow README.md instructions                 ║
╚══════════════════════════════════════════════════════════════╝

Generated code preview:
"""
        main_file = "App.js" if app_type == "react_native" else "main.dart"
        main_path = os.path.join(project_dir, main_file)
        if os.path.exists(main_path):
            with open(main_path, "r") as f:
                content = f.read()[:500]
                response += f"```\n{content}\n...\n```\n"
        
        response += "\nWould you like me to add more screens or features?"
        return response

    def _landing_page_template(self) -> Dict:
        """Landing page template."""
        return {
            "html": '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{name}</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">{name}</div>
        <ul class="nav-links">
            <li><a href="#home">Home</a></li>
            <li><a href="#features">Features</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#contact">Contact</a></li>
        </ul>
    </nav>
    
    <section id="home" class="hero">
        <div class="hero-content">
            <h1>Welcome to {name}</h1>
            <p>{description}</p>
            <button class="cta-button">Get Started</button>
        </div>
    </section>
    
    <section id="features" class="features">
        <h2>Features</h2>
        <div class="feature-grid">
            <div class="feature-card">
                <div class="feature-icon">🚀</div>
                <h3>Fast</h3>
                <p>Lightning fast performance</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">🔒</div>
                <h3>Secure</h3>
                <p>Top-notch security</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">📱</div>
                <h3>Responsive</h3>
                <p>Works on all devices</p>
            </div>
        </div>
    </section>
    
    <section id="about" class="about">
        <h2>About Us</h2>
        <p>We are dedicated to providing the best service possible.</p>
    </section>
    
    <section id="contact" class="contact">
        <h2>Contact Us</h2>
        <form class="contact-form">
            <input type="text" placeholder="Your Name" required>
            <input type="email" placeholder="Your Email" required>
            <textarea placeholder="Your Message" required></textarea>
            <button type="submit">Send Message</button>
        </form>
    </section>
    
    <footer>
        <p>&copy; 2024 {name}. All rights reserved.</p>
    </footer>
    
    <script src="script.js"></script>
</body>
</html>''',
            "css": '''* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
}

.navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 5%;
    background: #fff;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    position: fixed;
    width: 100%;
    top: 0;
    z-index: 1000;
}

.logo {
    font-size: 1.5rem;
    font-weight: bold;
    color: #2563eb;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    text-decoration: none;
    color: #333;
    transition: color 0.3s;
}

.nav-links a:hover {
    color: #2563eb;
}

.hero {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    text-align: center;
    padding: 0 5%;
}

.hero-content h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
}

.hero-content p {
    font-size: 1.2rem;
    margin-bottom: 2rem;
    opacity: 0.9;
}

.cta-button {
    padding: 1rem 2rem;
    font-size: 1.1rem;
    background: #fff;
    color: #667eea;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    transition: transform 0.3s, box-shadow 0.3s;
}

.cta-button:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 20px rgba(0,0,0,0.2);
}

.features {
    padding: 5rem 5%;
    text-align: center;
    background: #f8fafc;
}

.features h2 {
    font-size: 2rem;
    margin-bottom: 3rem;
    color: #1e293b;
}

.feature-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    max-width: 1200px;
    margin: 0 auto;
}

.feature-card {
    background: white;
    padding: 2rem;
    border-radius: 10px;
    box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    transition: transform 0.3s;
}

.feature-card:hover {
    transform: translateY(-10px);
}

.feature-icon {
    font-size: 3rem;
    margin-bottom: 1rem;
}

.feature-card h3 {
    color: #1e293b;
    margin-bottom: 0.5rem;
}

.about {
    padding: 5rem 5%;
    text-align: center;
}

.about h2 {
    font-size: 2rem;
    margin-bottom: 1rem;
    color: #1e293b;
}

.about p {
    max-width: 800px;
    margin: 0 auto;
    color: #64748b;
}

.contact {
    padding: 5rem 5%;
    background: #1e293b;
    color: white;
    text-align: center;
}

.contact h2 {
    font-size: 2rem;
    margin-bottom: 2rem;
}

.contact-form {
    max-width: 600px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.contact-form input,
.contact-form textarea {
    padding: 1rem;
    border: none;
    border-radius: 5px;
    font-size: 1rem;
}

.contact-form textarea {
    min-height: 150px;
    resize: vertical;
}

.contact-form button {
    padding: 1rem 2rem;
    background: #2563eb;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.3s;
}

.contact-form button:hover {
    background: #1d4ed8;
}

footer {
    text-align: center;
    padding: 2rem;
    background: #0f172a;
    color: white;
}

@media (max-width: 768px) {
    .navbar {
        flex-direction: column;
        gap: 1rem;
    }
    
    .nav-links {
        gap: 1rem;
    }
    
    .hero-content h1 {
        font-size: 2rem;
    }
}''',
            "js": '''document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

document.querySelector('.contact-form').addEventListener('submit', function(e) {
    e.preventDefault();
    alert('Thank you for your message! We will get back to you soon.');
    this.reset();
});

window.addEventListener('scroll', function() {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.background = 'rgba(255,255,255,0.95)';
        navbar.style.boxShadow = '0 2px 20px rgba(0,0,0,0.1)';
    } else {
        navbar.style.background = '#fff';
        navbar.style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
    }
});'''
        }

    def _portfolio_template(self) -> Dict:
        """Portfolio template."""
        return {
            "html": '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{name} - Portfolio</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">{name}</div>
        <ul class="nav-links">
            <li><a href="#home">Home</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#projects">Projects</a></li>
            <li><a href="#skills">Skills</a></li>
            <li><a href="#contact">Contact</a></li>
        </ul>
    </nav>
    
    <section id="home" class="hero">
        <div class="hero-content">
            <div class="profile-image">👨‍💻</div>
            <h1>Hi, I'm {name}</h1>
            <p class="tagline">Full Stack Developer & Designer</p>
            <div class="social-links">
                <a href="#" class="social-link">GitHub</a>
                <a href="#" class="social-link">LinkedIn</a>
                <a href="#" class="social-link">Twitter</a>
            </div>
        </div>
    </section>
    
    <section id="about" class="about">
        <h2>About Me</h2>
        <div class="about-content">
            <p>I'm a passionate developer who loves creating beautiful and functional web applications. With expertise in modern technologies, I bring ideas to life through code.</p>
        </div>
    </section>
    
    <section id="projects" class="projects">
        <h2>My Projects</h2>
        <div class="project-grid">
            <div class="project-card">
                <div class="project-image">🎨</div>
                <h3>E-Commerce Platform</h3>
                <p>Full-stack online store with payment integration</p>
                <div class="project-tags">
                    <span>React</span>
                    <span>Node.js</span>
                    <span>MongoDB</span>
                </div>
            </div>
            <div class="project-card">
                <div class="project-image">📱</div>
                <h3>Mobile App</h3>
                <p>Cross-platform mobile application</p>
                <div class="project-tags">
                    <span>React Native</span>
                    <span>Firebase</span>
                </div>
            </div>
            <div class="project-card">
                <div class="project-image">🤖</div>
                <h3>AI Dashboard</h3>
                <p>Machine learning analytics dashboard</p>
                <div class="project-tags">
                    <span>Python</span>
                    <span>TensorFlow</span>
                    <span>D3.js</span>
                </div>
            </div>
        </div>
    </section>
    
    <section id="skills" class="skills">
        <h2>Skills</h2>
        <div class="skills-grid">
            <div class="skill-item">
                <span class="skill-name">JavaScript</span>
                <div class="skill-bar"><div class="skill-progress" style="width: 90%"></div></div>
            </div>
            <div class="skill-item">
                <span class="skill-name">React</span>
                <div class="skill-bar"><div class="skill-progress" style="width: 85%"></div></div>
            </div>
            <div class="skill-item">
                <span class="skill-name">Node.js</span>
                <div class="skill-bar"><div class="skill-progress" style="width: 80%"></div></div>
            </div>
            <div class="skill-item">
                <span class="skill-name">Python</span>
                <div class="skill-bar"><div class="skill-progress" style="width: 75%"></div></div>
            </div>
        </div>
    </section>
    
    <section id="contact" class="contact">
        <h2>Get In Touch</h2>
        <form class="contact-form">
            <input type="text" placeholder="Your Name" required>
            <input type="email" placeholder="Your Email" required>
            <textarea placeholder="Your Message" required></textarea>
            <button type="submit">Send Message</button>
        </form>
    </section>
    
    <footer>
        <p>&copy; 2024 {name}. All rights reserved.</p>
    </footer>
    
    <script src="script.js"></script>
</body>
</html>''',
            "css": '''* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
}

.navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 5%;
    background: rgba(255,255,255,0.95);
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    position: fixed;
    width: 100%;
    top: 0;
    z-index: 1000;
}

.logo {
    font-size: 1.5rem;
    font-weight: bold;
    color: #2563eb;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    text-decoration: none;
    color: #333;
    transition: color 0.3s;
}

.nav-links a:hover {
    color: #2563eb;
}

.hero {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
    color: white;
    text-align: center;
}

.profile-image {
    font-size: 6rem;
    margin-bottom: 1rem;
}

.hero h1 {
    font-size: 3rem;
    margin-bottom: 0.5rem;
}

.tagline {
    font-size: 1.3rem;
    opacity: 0.9;
    margin-bottom: 2rem;
}

.social-links {
    display: flex;
    gap: 1rem;
    justify-content: center;
}

.social-link {
    padding: 0.5rem 1.5rem;
    background: rgba(255,255,255,0.1);
    color: white;
    text-decoration: none;
    border-radius: 20px;
    transition: background 0.3s;
}

.social-link:hover {
    background: #2563eb;
}

.about {
    padding: 5rem 5%;
    text-align: center;
    background: #f8fafc;
}

.about h2 {
    font-size: 2rem;
    margin-bottom: 2rem;
    color: #1e293b;
}

.about-content {
    max-width: 800px;
    margin: 0 auto;
}

.projects {
    padding: 5rem 5%;
}

.projects h2 {
    font-size: 2rem;
    margin-bottom: 3rem;
    text-align: center;
    color: #1e293b;
}

.project-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 2rem;
    max-width: 1200px;
    margin: 0 auto;
}

.project-card {
    background: white;
    border-radius: 10px;
    overflow: hidden;
    box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    transition: transform 0.3s;
}

.project-card:hover {
    transform: translateY(-10px);
}

.project-image {
    height: 150px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 4rem;
}

.project-card h3 {
    padding: 1rem 1.5rem 0.5rem;
    color: #1e293b;
}

.project-card p {
    padding: 0 1.5rem;
    color: #64748b;
}

.project-tags {
    padding: 1rem 1.5rem;
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
}

.project-tags span {
    padding: 0.25rem 0.75rem;
    background: #e2e8f0;
    border-radius: 15px;
    font-size: 0.8rem;
    color: #475569;
}

.skills {
    padding: 5rem 5%;
    background: #f8fafc;
}

.skills h2 {
    font-size: 2rem;
    margin-bottom: 3rem;
    text-align: center;
    color: #1e293b;
}

.skills-grid {
    max-width: 600px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

.skill-item {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.skill-name {
    font-weight: 600;
    color: #1e293b;
}

.skill-bar {
    height: 10px;
    background: #e2e8f0;
    border-radius: 5px;
    overflow: hidden;
}

.skill-progress {
    height: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 5px;
}

.contact {
    padding: 5rem 5%;
    text-align: center;
}

.contact h2 {
    font-size: 2rem;
    margin-bottom: 2rem;
    color: #1e293b;
}

.contact-form {
    max-width: 600px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.contact-form input,
.contact-form textarea {
    padding: 1rem;
    border: 2px solid #e2e8f0;
    border-radius: 5px;
    font-size: 1rem;
    transition: border-color 0.3s;
}

.contact-form input:focus,
.contact-form textarea:focus {
    outline: none;
    border-color: #2563eb;
}

.contact-form textarea {
    min-height: 150px;
    resize: vertical;
}

.contact-form button {
    padding: 1rem 2rem;
    background: #2563eb;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.3s;
}

.contact-form button:hover {
    background: #1d4ed8;
}

footer {
    text-align: center;
    padding: 2rem;
    background: #1e293b;
    color: white;
}

@media (max-width: 768px) {
    .navbar {
        flex-direction: column;
        gap: 1rem;
    }
    
    .nav-links {
        gap: 1rem;
    }
    
    .hero h1 {
        font-size: 2rem;
    }
}'''
        }

    def _blog_template(self) -> Dict:
        """Blog template."""
        return {
            "html": '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{name} - Blog</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">{name}</div>
        <ul class="nav-links">
            <li><a href="#home">Home</a></li>
            <li><a href="#posts">Posts</a></li>
            <li><a href="#categories">Categories</a></li>
            <li><a href="#about">About</a></li>
        </ul>
    </nav>
    
    <header id="home" class="hero">
        <h1>Welcome to {name}</h1>
        <p>Thoughts, stories and ideas</p>
    </header>
    
    <main>
        <section id="posts" class="posts">
            <article class="post-card">
                <div class="post-image">📝</div>
                <div class="post-content">
                    <span class="post-date">January 15, 2024</span>
                    <h2>Getting Started with Web Development</h2>
                    <p>Learn the basics of HTML, CSS, and JavaScript to start your journey...</p>
                    <a href="#" class="read-more">Read More →</a>
                </div>
            </article>
            
            <article class="post-card">
                <div class="post-image">💻</div>
                <div class="post-content">
                    <span class="post-date">January 10, 2024</span>
                    <h2>10 Tips for Better Code</h2>
                    <p>Improve your coding skills with these essential tips...</p>
                    <a href="#" class="read-more">Read More →</a>
                </div>
            </article>
            
            <article class="post-card">
                <div class="post-image">🚀</div>
                <div class="post-content">
                    <span class="post-date">January 5, 2024</span>
                    <h2>The Future of Technology</h2>
                    <p>Explore what's coming in the world of tech...</p>
                    <a href="#" class="read-more">Read More →</a>
                </div>
            </article>
        </section>
        
        <aside id="categories" class="sidebar">
            <h3>Categories</h3>
            <ul>
                <li><a href="#">Technology</a></li>
                <li><a href="#">Web Development</a></li>
                <li><a href="#">Design</a></li>
                <li><a href="#">Life</a></li>
            </ul>
        </aside>
    </main>
    
    <footer>
        <p>&copy; 2024 {name}. All rights reserved.</p>
    </footer>
</body>
</html>''',
            "css": '''* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Georgia', serif;
    line-height: 1.8;
    color: #333;
}

.navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 5%;
    background: #fff;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.logo {
    font-size: 1.5rem;
    font-weight: bold;
    color: #1e293b;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    text-decoration: none;
    color: #333;
    transition: color 0.3s;
}

.nav-links a:hover {
    color: #2563eb;
}

.hero {
    padding: 5rem 5%;
    text-align: center;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
}

.hero h1 {
    font-size: 3rem;
    margin-bottom: 0.5rem;
    color: #1e293b;
}

.hero p {
    font-size: 1.2rem;
    color: #64748b;
}

main {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 3rem;
    padding: 3rem 5%;
    max-width: 1400px;
    margin: 0 auto;
}

.post-card {
    display: flex;
    background: white;
    border-radius: 10px;
    overflow: hidden;
    box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    margin-bottom: 2rem;
    transition: transform 0.3s;
}

.post-card:hover {
    transform: translateY(-5px);
}

.post-image {
    width: 200px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 3rem;
}

.post-content {
    padding: 1.5rem;
}

.post-date {
    font-size: 0.9rem;
    color: #64748b;
}

.post-content h2 {
    margin: 0.5rem 0;
    color: #1e293b;
}

.post-content p {
    color: #64748b;
    margin-bottom: 1rem;
}

.read-more {
    color: #2563eb;
    text-decoration: none;
    font-weight: 600;
}

.read-more:hover {
    text-decoration: underline;
}

.sidebar {
    background: #f8fafc;
    padding: 2rem;
    border-radius: 10px;
    height: fit-content;
}

.sidebar h3 {
    margin-bottom: 1rem;
    color: #1e293b;
}

.sidebar ul {
    list-style: none;
}

.sidebar li {
    margin-bottom: 0.5rem;
}

.sidebar a {
    color: #64748b;
    text-decoration: none;
    transition: color 0.3s;
}

.sidebar a:hover {
    color: #2563eb;
}

footer {
    text-align: center;
    padding: 2rem;
    background: #1e293b;
    color: white;
}

@media (max-width: 768px) {
    main {
        grid-template-columns: 1fr;
    }
    
    .post-card {
        flex-direction: column;
    }
    
    .post-image {
        width: 100%;
        height: 150px;
    }
}'''
        }

    def _ecommerce_template(self) -> Dict:
        """E-commerce template."""
        return {
            "html": '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{name} - Shop</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">{name}</div>
        <ul class="nav-links">
            <li><a href="#home">Home</a></li>
            <li><a href="#products">Products</a></li>
            <li><a href="#cart">Cart (0)</a></li>
        </ul>
    </nav>
    
    <header id="home" class="hero">
        <h1>Welcome to {name}</h1>
        <p>Discover amazing products at great prices</p>
        <button class="cta-button">Shop Now</button>
    </header>
    
    <section id="products" class="products">
        <h2>Featured Products</h2>
        <div class="product-grid">
            <div class="product-card">
                <div class="product-image">👟</div>
                <h3>Premium Sneakers</h3>
                <p class="price">$99.99</p>
                <button class="add-to-cart">Add to Cart</button>
            </div>
            <div class="product-card">
                <div class="product-image">⌚</div>
                <h3>Smart Watch</h3>
                <p class="price">$199.99</p>
                <button class="add-to-cart">Add to Cart</button>
            </div>
            <div class="product-card">
                <div class="product-image">🎧</div>
                <h3>Wireless Headphones</h3>
                <p class="price">$149.99</p>
                <button class="add-to-cart">Add to Cart</button>
            </div>
            <div class="product-card">
                <div class="product-image">📱</div>
                <h3>Phone Case</h3>
                <p class="price">$29.99</p>
                <button class="add-to-cart">Add to Cart</button>
            </div>
        </div>
    </section>
    
    <footer>
        <p>&copy; 2024 {name}. All rights reserved.</p>
    </footer>
    
    <script src="script.js"></script>
</body>
</html>''',
            "css": '''* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 5%;
    background: #fff;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    position: sticky;
    top: 0;
    z-index: 1000;
}

.logo {
    font-size: 1.5rem;
    font-weight: bold;
    color: #2563eb;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    text-decoration: none;
    color: #333;
    font-weight: 500;
}

.hero {
    padding: 5rem 5%;
    text-align: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
}

.hero h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
}

.cta-button {
    padding: 1rem 2rem;
    font-size: 1.1rem;
    background: #fff;
    color: #667eea;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    transition: transform 0.3s;
}

.cta-button:hover {
    transform: scale(1.05);
}

.products {
    padding: 5rem 5%;
    text-align: center;
}

.products h2 {
    font-size: 2rem;
    margin-bottom: 3rem;
    color: #1e293b;
}

.product-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    max-width: 1200px;
    margin: 0 auto;
}

.product-card {
    background: white;
    border-radius: 10px;
    padding: 1.5rem;
    box-shadow: 0 5px 15px rgba(0,0,0,0.1);
    transition: transform 0.3s;
}

.product-card:hover {
    transform: translateY(-10px);
}

.product-image {
    font-size: 4rem;
    margin-bottom: 1rem;
}

.product-card h3 {
    color: #1e293b;
    margin-bottom: 0.5rem;
}

.price {
    font-size: 1.3rem;
    color: #2563eb;
    font-weight: bold;
    margin-bottom: 1rem;
}

.add-to-cart {
    width: 100%;
    padding: 0.75rem;
    background: #2563eb;
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.3s;
}

.add-to-cart:hover {
    background: #1d4ed8;
}

footer {
    text-align: center;
    padding: 2rem;
    background: #1e293b;
    color: white;
}''',
            "js": '''let cart = [];

document.querySelectorAll('.add-to-cart').forEach(button => {
    button.addEventListener('click', function() {
        const product = this.parentElement;
        const name = product.querySelector('h3').textContent;
        const price = product.querySelector('.price').textContent;
        
        cart.push({ name, price });
        updateCartCount();
        
        alert(`${name} added to cart!`);
    });
});

function updateCartCount() {
    document.querySelector('.nav-links a[href="#cart"]').textContent = `Cart (${cart.length})`;
}

document.querySelector('.cta-button').addEventListener('click', function() {
    document.querySelector('#products').scrollIntoView({ behavior: 'smooth' });
});'''
        }

    def _business_template(self) -> Dict:
        """Business template."""
        return self._landing_page_template()

    def _restaurant_template(self) -> Dict:
        """Restaurant template."""
        return self._landing_page_template()

    def _agency_template(self) -> Dict:
        """Agency template."""
        return self._landing_page_template()

    def _resume_template(self) -> Dict:
        """Resume template."""
        return self._portfolio_template()

    def _react_native_template(self) -> Dict:
        """React Native template."""
        return {
            "App.js": '''import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList } from 'react-native';

const App = () => {
  const [items, setItems] = useState([
    { id: '1', title: 'Welcome to {name}', description: 'Your new React Native app' },
    { id: '2', title: 'Get Started', description: 'Start building your app' },
    { id: '3', title: 'Learn More', description: 'Explore the documentation' },
  ]);

  const renderItem = ({ item }) => (
    <View style={styles.item}>
      <Text style={styles.itemTitle}>{item.title}</Text>
      <Text style={styles.itemDescription}>{item.description}</Text>
    </View>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.header}>{name}</Text>
      <FlatList
        data={items}
        renderItem={renderItem}
        keyExtractor={item => item.id}
        style={styles.list}
      />
      <TouchableOpacity style={styles.button}>
        <Text style={styles.buttonText}>Get Started</Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    paddingTop: 50,
  },
  header: {
    fontSize: 28,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 30,
    color: '#333',
  },
  list: {
    flex: 1,
    paddingHorizontal: 20,
  },
  item: {
    backgroundColor: 'white',
    padding: 20,
    marginVertical: 8,
    marginHorizontal: 16,
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  itemTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  itemDescription: {
    fontSize: 14,
    color: '#666',
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 15,
    margin: 20,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
});

export default App;''',
            "package.json": '''{
  "name": "{name}",
  "version": "1.0.0",
  "main": "node_modules/expo/AppEntry.js",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web"
  },
  "dependencies": {{
    "expo": "~49.0.0",
    "react": "18.2.0",
    "react-native": "0.72.6"
  }},
  "devDependencies": {{
    "@babel/core": "^7.20.0"
  }}
}''',
            "README.md": '''# {name}

A React Native mobile application.

## Getting Started

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the development server:
   ```bash
   npm start
   ```

3. Run on your device:
   - iOS: `npm run ios`
   - Android: `npm run android`
   - Web: `npm run web`

## Features

- Modern UI design
- Cross-platform support
- Easy to customize

## Learn More

- [React Native Documentation](https://reactnative.dev/)
- [Expo Documentation](https://docs.expo.dev/)'''
        }

    def _flutter_template(self) -> Dict:
        """Flutter template."""
        return {
            "main.dart": '''import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{name}',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{name}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_android,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to {name}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your new Flutter app is ready!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button pressed!')),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FAB pressed!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}''',
            "pubspec.yaml": '''name: {name}
description: A new Flutter project.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true''',
            "README.md": '''# {name}

A Flutter mobile application.

## Getting Started

1. Install Flutter SDK
2. Run `flutter pub get`
3. Run `flutter run`

## Features

- Modern UI design
- Cross-platform support (iOS & Android)
- Material Design components
- Easy to customize

## Learn More

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language](https://dart.dev/)'''
        }
