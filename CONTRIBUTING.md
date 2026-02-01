# Contributing to Amorae

Thank you for your interest in contributing to Amorae! We welcome contributions from the community.

## Getting Started

1. **Fork the repository** and clone it locally
2. **Set up your development environment** following the instructions in [README.md](README.md)
3. **Create a new branch** for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Backend Changes

1. Navigate to the `backend/` directory
2. Activate your virtual environment
3. Make your changes
4. Test your changes locally:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
5. Ensure all endpoints work as expected

### Frontend Changes

1. Make your changes in the appropriate directory under `lib/`
2. Test on both Android and iOS if possible:
   ```bash
   flutter run
   ```
3. Ensure hot reload works and no errors appear
4. Test the UI/UX thoroughly

## Code Style

### Flutter/Dart

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep files under 500 lines when possible
- Use `const` constructors where applicable

### Python

- Follow [PEP 8](https://pep8.org/) style guide
- Use type hints for function parameters and return values
- Write docstrings for all functions and classes
- Keep functions focused and single-purpose

## Commit Messages

Write clear, concise commit messages:

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests when relevant

Examples:
```
Add emoji level picker to settings screen
Fix message duplication issue in chat
Update README with Firebase setup instructions
```

## Pull Request Process

1. **Update documentation** if you've changed APIs or added features
2. **Add tests** if applicable
3. **Ensure the code builds** without errors or warnings
4. **Update the README.md** if needed
5. **Create a Pull Request** with a clear description of changes

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How has this been tested?

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented complex code
- [ ] I have updated documentation
- [ ] My changes generate no new warnings
- [ ] I have tested on Android/iOS
```

## Reporting Bugs

When reporting bugs, please include:

1. **Description**: Clear description of the bug
2. **Steps to Reproduce**: Detailed steps to reproduce the issue
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**:
   - OS and version
   - Flutter version
   - Python version
   - Device (if mobile)
6. **Screenshots/Logs**: Any relevant error messages or screenshots

## Feature Requests

We welcome feature requests! Please include:

1. **Use Case**: Why this feature would be useful
2. **Description**: Detailed description of the feature
3. **Mockups**: UI mockups if applicable
4. **Implementation Ideas**: Any thoughts on how to implement

## Code Review Process

1. At least one maintainer will review your PR
2. Address any requested changes
3. Once approved, a maintainer will merge your PR

## Questions?

Feel free to open an issue for any questions about contributing!

## Code of Conduct

Be respectful and constructive in all interactions. We are building this together!

---

Thank you for contributing to Amorae! 💖
