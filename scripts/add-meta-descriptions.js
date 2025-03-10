#!/usr/bin/env node

/**
 * Add Meta Descriptions
 * 
 * This script adds meta descriptions to blog posts in the _posts directory.
 * It will only add descriptions to posts that don't already have them.
 * 
 * Usage:
 *   node add-meta-descriptions.js             # Process all posts
 *   node add-meta-descriptions.js <filename>  # Process a specific post
 */

const fs = require('fs');
const path = require('path');

// Configuration
const POSTS_DIR = path.join(__dirname, '..', '_posts');

// Parse command line arguments
const args = process.argv.slice(2);
const specificPost = args.length > 0 ? args[0] : null;

/**
 * Extract front matter from a post
 * @param {string} content - The content of the post
 * @returns {Object} - The extracted front matter and content
 */
function extractFrontMatter(content) {
  const frontMatterRegex = /^---\s*\n([\s\S]*?)\n---\s*\n/;
  const match = content.match(frontMatterRegex);
  
  if (!match) {
    return {
      frontMatter: '',
      content: content,
      parsed: {}
    };
  }
  
  const frontMatter = match[0];
  const remainingContent = content.slice(frontMatter.length);
  
  // Parse front matter
  const parsed = {};
  const lines = match[1].split('\n');
  
  lines.forEach(line => {
    const colonIndex = line.indexOf(':');
    if (colonIndex !== -1) {
      const key = line.slice(0, colonIndex).trim();
      let value = line.slice(colonIndex + 1).trim();
      
      // Handle arrays
      if (value.startsWith('[') && value.endsWith(']')) {
        value = value.slice(1, -1).split(',').map(item => {
          // Remove quotes and trim
          return item.replace(/['"]/g, '').trim();
        });
      } else if (value.startsWith('"') && value.endsWith('"')) {
        // Handle quoted strings
        value = value.slice(1, -1);
      }
      
      parsed[key] = value;
    }
  });
  
  return {
    original: frontMatter,
    parsed: parsed,
    content: remainingContent
  };
}

/**
 * Generate a meta description from post content
 * @param {string} content - The content of the post
 * @returns {string} - The generated meta description
 */
function generateMetaDescription(content) {
  const { parsed, content: postContent } = extractFrontMatter(content);
  
  // Extract the first paragraph that's not a heading
  const paragraphs = postContent.split('\n\n');
  let firstParagraph = '';
  
  for (const paragraph of paragraphs) {
    // Skip headings, code blocks, and empty lines
    if (!paragraph.startsWith('#') && 
        !paragraph.startsWith('```') && 
        paragraph.trim().length > 0) {
      firstParagraph = paragraph.trim();
      break;
    }
  }
  
  // Clean up the paragraph (remove markdown formatting)
  firstParagraph = firstParagraph
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Replace markdown links with just the text
    .replace(/\*\*([^*]+)\*\*/g, '$1')       // Remove bold formatting
    .replace(/\*([^*]+)\*/g, '$1')           // Remove italic formatting
    .replace(/`([^`]+)`/g, '$1')             // Remove inline code formatting
    .trim();
  
  // Limit to 160 characters and add ellipsis if needed
  if (firstParagraph.length > 157) {
    firstParagraph = firstParagraph.substring(0, 157) + '...';
  }
  
  return firstParagraph;
}

/**
 * Add meta description to a post
 * @param {string} filePath - The path to the post file
 * @returns {Object} - The result of the operation
 */
function addMetaDescription(filePath) {
  // Read file content
  const content = fs.readFileSync(filePath, 'utf8');
  
  // Extract front matter
  const { original, parsed, content: postContent } = extractFrontMatter(content);
  
  // Check if already has a description
  if (parsed.description) {
    return {
      filePath,
      hasDescription: true,
      updated: false,
      description: parsed.description
    };
  }
  
  // Generate description
  const description = generateMetaDescription(content);
  
  // Create a copy of the parsed front matter
  const improved = { ...parsed };
  improved.description = description;
  
  // Generate new front matter
  let newFrontMatter = '---\n';
  
  // Add title
  if (improved.title) {
    newFrontMatter += `title: "${improved.title}"\n`;
  }
  
  // Add layout
  if (improved.layout) {
    newFrontMatter += `layout: ${improved.layout}\n`;
  }
  
  // Add categories
  if (improved.categories) {
    if (Array.isArray(improved.categories)) {
      newFrontMatter += 'categories: [';
      newFrontMatter += improved.categories.map(c => `'${c}'`).join(', ');
      newFrontMatter += ']\n';
    } else {
      newFrontMatter += `categories: ${improved.categories}\n`;
    }
  }
  
  // Add tags
  if (improved.tags) {
    if (Array.isArray(improved.tags)) {
      newFrontMatter += 'tags: [';
      newFrontMatter += improved.tags.map(t => `'${t}'`).join(', ');
      newFrontMatter += ']\n';
    } else {
      newFrontMatter += `tags: ${improved.tags}\n`;
    }
  }
  
  // Add description
  newFrontMatter += `description: "${description}"\n`;
  
  // Add any other front matter properties
  Object.entries(improved).forEach(([key, value]) => {
    if (!['title', 'layout', 'categories', 'tags', 'description'].includes(key)) {
      if (typeof value === 'string') {
        newFrontMatter += `${key}: ${value}\n`;
      } else if (Array.isArray(value)) {
        newFrontMatter += `${key}: [${value.join(', ')}]\n`;
      } else {
        newFrontMatter += `${key}: ${JSON.stringify(value)}\n`;
      }
    }
  });
  
  newFrontMatter += '---\n';
  
  // Replace original front matter with new one
  const updatedContent = content.replace(original, newFrontMatter);
  
  // Write updated content back to file
  fs.writeFileSync(filePath, updatedContent, 'utf8');
  
  return {
    filePath,
    hasDescription: false,
    updated: true,
    description
  };
}

/**
 * Process all posts in the directory
 */
function processAllPosts() {
  console.log('Processing all posts in', POSTS_DIR);
  
  // Get all markdown files in the directory
  const files = fs.readdirSync(POSTS_DIR)
    .filter(file => (file.endsWith('.md') || file.endsWith('.markdown')) && !file.startsWith('_'))
    .map(file => path.join(POSTS_DIR, file));
  
  const results = {
    total: files.length,
    withDescription: 0,
    added: 0,
    failed: 0
  };
  
  // Process each file
  files.forEach(file => {
    try {
      const result = addMetaDescription(file);
      const filename = path.basename(file);
      
      if (result.hasDescription) {
        console.log(`✓ ${filename} already has a description`);
        results.withDescription++;
      } else if (result.updated) {
        console.log(`+ ${filename}: Added description: "${result.description}"`);
        results.added++;
      } else {
        console.log(`✗ ${filename}: Could not add a description`);
        results.failed++;
      }
    } catch (error) {
      console.error(`Error processing ${file}:`, error.message);
      results.failed++;
    }
  });
  
  // Print summary
  console.log('\nSummary:');
  console.log(`Total posts: ${results.total}`);
  console.log(`Posts with descriptions: ${results.withDescription}`);
  console.log(`Descriptions added: ${results.added}`);
  console.log(`Failed: ${results.failed}`);
}

/**
 * Process a specific post
 * @param {string} filename - The filename of the post to process
 */
function processSpecificPost(filename) {
  const filePath = path.join(POSTS_DIR, filename);
  
  if (!fs.existsSync(filePath)) {
    console.error(`Error: Post file not found: ${filename}`);
    return;
  }
  
  console.log(`Processing post: ${filename}`);
  
  try {
    const result = addMetaDescription(filePath);
    
    if (result.hasDescription) {
      console.log('This post already has a meta description.');
    } else if (result.updated) {
      console.log(`Successfully added description: "${result.description}"`);
    } else {
      console.log('Could not add a description to this post.');
    }
  } catch (error) {
    console.error(`Error processing post: ${error.message}`);
  }
}

// Main function
function main() {
  if (specificPost) {
    processSpecificPost(specificPost);
  } else {
    processAllPosts();
  }
}

// Run the script
main(); 