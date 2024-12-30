# Face Drawing App

*Create and transform your drawings into unique artworks with the Face Drawing App!*

---

## Overview

The **Face Drawing App** allows users to draw freehand on a canvas and send their drawings to a custom API for processing. The generated image is returned and displayed, offering a seamless and interactive experience. This app is built with **Flutter** and integrates with an API to process images and generate a new version of the drawing.

---

## Features

- **Interactive Drawing**: Draw freely on a blank canvas with real-time touch support.
- **API Integration**: Send your drawing to a backend API for processing, and get a new image back.
- **Loading State**: Display a loading state with a beautiful progress indicator while waiting for the API response.
- **Customizable API URL**: Easily change the API URL via the settings menu.
- **Clean & Beautiful UI**: A minimalist interface with a soothing color scheme and user-friendly controls.

---

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Custom API (set your own endpoint)
- **Image Processing**: API handles the processing of the uploaded image and returns the result.

---


---

## Getting Started

### Prerequisites

To run the Face Drawing App locally, you'll need the following:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- A **working API** to process images (or you can use your own API endpoint).

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/FaceDrawingApp.git
   cd FaceDrawingApp
   ```

2. Install the dependencies:

   ```bash
   flutter pub get
   ```

3. Ensure you have a running API that processes images and update the API URL in the app. The default URL is set to:

   ```dart
   String _apiUrl = 'https://your-api-url.com';
   ```

4. Run the app:

   ```bash
   flutter run
   ```

---

## Usage

1. **Draw**: Use your finger or stylus to draw on the canvas area at the bottom of the screen.
2. **Generate**: Tap the **Generate** button (star icon) to send your drawing to the backend API for processing.
3. **View the Result**: The processed image will appear at the top of the screen. If no image appears, try resetting your drawing or check the API connection.
4. **Reset Drawing**: Tap the **Reset** button (refresh icon) to clear the canvas and start a new drawing.
5. **Change API URL**: Tap the **Settings** button (gear icon) in the top right corner to change the API URL if needed.

---

## API Endpoint

- **POST `/process-image`**: This endpoint accepts the uploaded image file and returns the processed image.

  **Request**:
  - **Body**: Multipart form-data containing an image file (PNG format recommended).

  **Response**:
  - A processed image in **JPG** format will be returned in the response.

---

## Customization

- **App Color Scheme**: The app uses a light blue color (`#bfd7ed`) for the main theme. You can change the colors by modifying the `theme` in `main.dart`.
- **API URL**: Change the default API URL by accessing the settings and providing a new URL.

---

## Contributing

We welcome contributions! If you'd like to improve this app, please fork the repository, make your changes, and submit a pull request.

---

## License

This project is open-source and available under the MIT License.

---

## Contact

Created by **Faidi Yassine** - [@yourusername](https://twitter.com/yourusername)  
Feel free to reach out for suggestions, issues, or collaboration!

---

Enjoy drawing! ✏️🎨

--- 

**Note**: Replace the placeholder images and text with actual links or content relevant to your project.
