const http = require('http');
const url = require('url');

const args = process.argv.slice(2);
let port = 8080;
let allowedOrigin = 'http://localhost:5555';

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--port' && args[i + 1]) port = parseInt(args[i + 1], 10);
  if (args[i] === '--origin' && args[i + 1]) allowedOrigin = args[i + 1];
}

let books = [
  { id: 1, title: 'Война и мир', isbn: '978-5-699-12014-7', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1, 3], copiesTotal: 5, copiesAvailable: 3, deletedAt: null },
  { id: 2, title: '1984', isbn: '978-5-17-080115-3', year: 1949, pages: 328, publisherId: 2, authorIds: [3], genreIds: [2], copiesTotal: 10, copiesAvailable: 7, deletedAt: null },
  { id: 3, title: 'Преступление и наказание', isbn: '978-5-389-06256-6', year: 1866, pages: 672, publisherId: 1, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 0, deletedAt: null },
];

const publishers = [
  { id: 1, name: 'Эксмо', city: 'Москва', supportedGenreIds: [1, 2, 3] },
  { id: 2, name: 'Питер', city: 'Санкт-Петербург', supportedGenreIds: [2] },
  { id: 3, name: 'АСТ', city: 'Москва', supportedGenreIds: [1, 3] },
];

const authors = [
  { id: 1, name: 'Лев Толстой', country: 'Россия', birthYear: 1828, biography: 'Русский писатель' },
  { id: 2, name: 'Федор Достоевский', country: 'Россия', birthYear: 1821, biography: 'Классик литературы' },
  { id: 3, name: 'Джордж Оруэлл', country: 'Великобритания', birthYear: 1903, biography: 'Английский публицист' },
];

const genres = [
  { id: 1, name: 'Классика', description: 'Классические произведения' },
  { id: 2, name: 'Фантастика', description: 'Научная фантастика' },
  { id: 3, name: 'Роман', description: 'Художественная проза' },
];

const readers = [
  { id: 1, fullName: 'Иванов Иван Иванович', email: 'ivanov@example.com', phone: '+7 999 111-22-33', card: { cardNumber: 'CARD-1001', issueDate: '2026-01-15T00:00:00.000Z', status: 'Активен' } },
];

function setCors(req, res) {
  res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data));
}

const server = http.createServer((req, res) => {
  setCors(req, res);
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  const query = parsedUrl.query;

  const delay = query.__delay ? parseInt(query.__delay, 10) : 0;
  const fail = query.__fail ? parseInt(query.__fail, 10) : 0;

  setTimeout(() => {
    if (fail > 0) {
      return sendJson(res, fail, { message: `Принудительный сбой сервера (код ${fail})` });
    }

    if (path === '/api/__health') {
      return sendJson(res, 200, { status: 'ok', serverTime: new Date().toISOString() });
    }

    if (path === '/api/authors' && req.method === 'GET') {
      return sendJson(res, 200, { items: authors, total: authors.length });
    }
    if (path === '/api/genres' && req.method === 'GET') {
      return sendJson(res, 200, { items: genres, total: genres.length });
    }
    if (path === '/api/publishers' && req.method === 'GET') {
      return sendJson(res, 200, { items: publishers, total: publishers.length });
    }
    if (path === '/api/readers' && req.method === 'GET') {
      return sendJson(res, 200, { items: readers, total: readers.length });
    }

    if (path === '/api/books' && req.method === 'GET') {
      let filtered = books.filter(b => query.includeDeleted === 'true' ? b.deletedAt !== null : b.deletedAt === null);
      if (query.search) {
        const s = query.search.toLowerCase();
        filtered = filtered.filter(b => b.title.toLowerCase().includes(s) || b.isbn.toLowerCase().includes(s));
      }
      if (query.sort) {
        const [field, order] = query.sort.split(',');
        filtered.sort((a, b) => {
          const valA = a[field] ?? '';
          const valB = b[field] ?? '';
          return order === 'desc' ? (valA > valB ? -1 : 1) : (valA > valB ? 1 : -1);
        });
      }
      const page = parseInt(query.page || '1', 10);
      const size = parseInt(query.size || '5', 10);
      const total = filtered.length;
      const items = filtered.slice((page - 1) * size, page * size);
      return sendJson(res, 200, { items, total, page, size });
    }

    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let payload = {};
      try { if (body) payload = JSON.parse(body); } catch (_) {}

      if (path === '/api/books' && req.method === 'POST') {
        const existing = books.find(b => b.isbn.trim().toLowerCase() === (payload.isbn || '').trim().toLowerCase() && !b.deletedAt);
        if (existing) {
          return sendJson(res, 422, {
            message: 'Ошибка валидации',
            errors: { isbn: 'Книга с таким ISBN уже зарегистрирована в каталоге' }
          });
        }
        const newId = books.length ? Math.max(...books.map(b => b.id)) + 1 : 1;
        const newBook = { id: newId, ...payload, deletedAt: null };
        books.push(newBook);
        return sendJson(res, 201, newBook);
      }

      if (path.startsWith('/api/books/') && req.method === 'PUT') {
        const id = parseInt(path.split('/')[3], 10);
        const idx = books.findIndex(b => b.id === id);
        if (idx === -1) return sendJson(res, 404, { message: 'Книга не найдена' });
        books[idx] = { ...books[idx], ...payload };
        return sendJson(res, 200, books[idx]);
      }

      if (path.endsWith('/restore') && req.method === 'POST') {
        const id = parseInt(path.split('/')[3], 10);
        const book = books.find(b => b.id === id);
        if (book) book.deletedAt = null;
        return sendJson(res, 200, { success: true });
      }

      if (path === '/api/books/bulk-delete' && req.method === 'POST') {
        const ids = payload.ids || [];
        books = books.filter(b => !ids.includes(b.id));
        return sendJson(res, 200, { deleted: ids.length });
      }

      if (path.startsWith('/api/books/') && req.method === 'DELETE') {
        const id = parseInt(path.split('/')[3], 10);
        if (query.hard === 'true') {
          books = books.filter(b => b.id !== id);
        } else {
          const book = books.find(b => b.id === id);
          if (book) book.deletedAt = new Date().toISOString();
        }
        return sendJson(res, 200, { success: true });
      }

      return sendJson(res, 404, { message: 'Эндпоинт не найден' });
    });
  }, delay);
});

server.listen(port, () => {
  console.log(`[Mock Server] Слушает порт ${port}, разрешён origin: ${allowedOrigin}`);
  console.log(`Проверка здоровья: http://localhost:${port}/api/__health`);
});

// Удержание процесса активным
process.stdin.resume();
setInterval(() => {}, 1000 * 60 * 60);

process.on('SIGINT', () => {
  console.log('\n[Mock Server] Остановлен пользователем через Ctrl+C');
  process.exit(0);
});