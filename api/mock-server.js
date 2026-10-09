const http = require('http');

const args = process.argv.slice(2);
let port = 8080;
let allowedOrigin = 'http://localhost:5555';
let tokenTtl = 900;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--port' && args[i + 1]) port = parseInt(args[i + 1], 10);
  if (args[i] === '--origin' && args[i + 1]) allowedOrigin = args[i + 1];
  if (args[i] === '--ttl' && args[i + 1]) tokenTtl = parseInt(args[i + 1], 10);
}

let users = [
  { id: 1, email: 'admin@bibl.ru', password: 'Password123!', name: 'Алексей Администратор', role: 'admin' },
  { id: 2, email: 'lib@bibl.ru', password: 'Password123!', name: 'Елена Библиотекарь', role: 'librarian' },
  { id: 3, email: 'reader@bibl.ru', password: 'Password123!', name: 'Иван Читатель', role: 'reader' },
];

let activeTokens = new Map();
let activeRefreshTokens = new Map();

let books = [
  { id: 1, title: 'Война и мир', isbn: '978-5-699-12014-7', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [1, 3], copiesTotal: 5, copiesAvailable: 3, deletedAt: null },
  { id: 2, title: '1984', isbn: '978-5-17-080115-3', year: 1949, pages: 328, publisherId: 2, authorIds: [3], genreIds: [2], copiesTotal: 10, copiesAvailable: 7, deletedAt: null },
  { id: 3, title: 'Преступление и наказание', isbn: '978-5-389-06256-6', year: 1866, pages: 672, publisherId: 1, authorIds: [2], genreIds: [1], copiesTotal: 4, copiesAvailable: 0, deletedAt: null },
];

let loans = [
  { id: 1, userId: 3, bookId: 1, bookTitle: 'Война и мир', issueDate: '2026-09-15', dueDate: '2026-10-15', isExtended: false },
  { id: 2, userId: 3, bookId: 2, bookTitle: '1984', issueDate: '2026-09-20', dueDate: '2026-10-20', isExtended: true },
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
  { id: 1, name: 'Иван Читатель', fullName: 'Иван Читатель', email: 'reader@bibl.ru', ticketNumber: 'ЧБ-001', phone: '+7 999 111-22-33' },
  { id: 2, name: 'Анна Смирнова', fullName: 'Анна Смирнова', email: 'anna@bibl.ru', ticketNumber: 'ЧБ-002', phone: '+7 999 222-33-44' },
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

function getAuthUser(req) {
  const auth = req.headers['authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  const token = auth.substring(7);
  const session = activeTokens.get(token);
  if (!session) return null;
  if (Date.now() > session.expiresAt) {
    activeTokens.delete(token);
    return null;
  }
  return users.find(u => u.id === session.userId) || null;
}

const server = http.createServer((req, res) => {
  setCors(req, res);
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const reqUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const path = reqUrl.pathname;
  const query = Object.fromEntries(reqUrl.searchParams);

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    let payload = {};
    try { if (body) payload = JSON.parse(body); } catch (_) {}

    if (path === '/api/__health') {
      return sendJson(res, 200, { status: 'ok', serverTime: new Date().toISOString() });
    }

    if (path === '/api/auth/login' && req.method === 'POST') {
      const user = users.find(u => u.email.toLowerCase() === (payload.email || '').toLowerCase().trim());
      if (!user || user.password !== payload.password) {
        return sendJson(res, 401, { message: 'Неверный адрес почты или пароль' });
      }
      const accessToken = 'acc_' + Math.random().toString(36).substring(2) + Date.now();
      const refreshToken = 'ref_' + Math.random().toString(36).substring(2) + Date.now();
      activeTokens.set(accessToken, { userId: user.id, expiresAt: Date.now() + tokenTtl * 1000 });
      activeRefreshTokens.set(refreshToken, user.id);
      return sendJson(res, 200, {
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, name: user.name, role: user.role }
      });
    }

    if (path === '/api/auth/register' && req.method === 'POST') {
      const existing = users.find(u => u.email.toLowerCase() === (payload.email || '').toLowerCase().trim());
      if (existing) {
        return sendJson(res, 422, { message: 'Ошибка валидации', errors: { email: 'Пользователь с такой почтой уже существует' } });
      }
      const newUser = {
        id: users.length + 1,
        email: payload.email.trim(),
        password: payload.password,
        name: payload.name.trim(),
        role: 'reader'
      };
      users.push(newUser);
      loans.push({
        id: loans.length + 1,
        userId: newUser.id,
        bookId: 1,
        bookTitle: 'Война и мир',
        issueDate: new Date().toISOString().split('T')[0],
        dueDate: '2026-10-25',
        isExtended: false
      });
      const accessToken = 'acc_' + Math.random().toString(36).substring(2) + Date.now();
      const refreshToken = 'ref_' + Math.random().toString(36).substring(2) + Date.now();
      activeTokens.set(accessToken, { userId: newUser.id, expiresAt: Date.now() + tokenTtl * 1000 });
      activeRefreshTokens.set(refreshToken, newUser.id);
      return sendJson(res, 201, {
        accessToken,
        refreshToken,
        user: { id: newUser.id, email: newUser.email, name: newUser.name, role: newUser.role }
      });
    }

    if (path === '/api/auth/refresh' && req.method === 'POST') {
      const token = payload.refreshToken;
      const userId = activeRefreshTokens.get(token);
      if (!userId) return sendJson(res, 401, { message: 'Недействительный refresh токен' });
      const user = users.find(u => u.id === userId);
      const newAccess = 'acc_' + Math.random().toString(36).substring(2) + Date.now();
      activeTokens.set(newAccess, { userId: user.id, expiresAt: Date.now() + tokenTtl * 1000 });
      return sendJson(res, 200, { accessToken: newAccess });
    }

    if (path === '/api/auth/me' && req.method === 'GET') {
      const user = getAuthUser(req);
      if (!user) return sendJson(res, 401, { message: 'Сессия истекла' });
      return sendJson(res, 200, { id: user.id, email: user.email, name: user.name, role: user.role });
    }

    // Справочники
    if (path === '/api/authors' && req.method === 'GET') return sendJson(res, 200, { items: authors, total: authors.length });
    if (path === '/api/genres' && req.method === 'GET') return sendJson(res, 200, { items: genres, total: genres.length });
    if (path === '/api/publishers' && req.method === 'GET') return sendJson(res, 200, { items: publishers, total: publishers.length });
    if (path === '/api/readers' && req.method === 'GET') return sendJson(res, 200, { items: readers, total: readers.length });

    // Экран Администратора
    if (path === '/api/admin/users' && req.method === 'GET') {
      const user = getAuthUser(req);
      if (!user || user.role !== 'admin') {
        return sendJson(res, 403, { message: 'Недостаточно прав: требуется роль администратора' });
      }
      return sendJson(res, 200, { items: users.map(u => ({ id: u.id, email: u.email, name: u.name, role: u.role })) });
    }

    // Экран Библиотекаря
    if (path === '/api/librarian/loans' && req.method === 'GET') {
      const user = getAuthUser(req);
      if (!user || user.role !== 'librarian') {
        return sendJson(res, 403, { message: 'Доступно только библиотекарю' });
      }
      const data = loans.map(l => {
        const u = users.find(x => x.id === l.userId);
        return { ...l, userName: u ? u.name : 'Иван Читатель' };
      });
      return sendJson(res, 200, { items: data });
    }

    if (path.startsWith('/api/librarian/loans/') && path.endsWith('/close') && req.method === 'POST') {
      const user = getAuthUser(req);
      if (!user || user.role !== 'librarian') {
        return sendJson(res, 403, { message: 'Доступно только библиотекарю' });
      }
      const id = parseInt(path.split('/')[4], 10);
      loans = loans.filter(l => l.id !== id);
      return sendJson(res, 200, { success: true });
    }

    // Экран Читателя
    if (path === '/api/my-loans' && req.method === 'GET') {
      const user = getAuthUser(req);
      if (!user) return sendJson(res, 401, { message: 'Требуется авторизация' });
      const userLoans = loans.filter(l => l.userId === user.id);
      return sendJson(res, 200, { items: userLoans });
    }

    if (path.startsWith('/api/my-loans/') && path.endsWith('/extend') && req.method === 'POST') {
      const user = getAuthUser(req);
      if (!user) return sendJson(res, 401, { message: 'Требуется авторизация' });
      const loanId = parseInt(path.split('/')[3], 10);
      const loan = loans.find(l => l.id === loanId && l.userId === user.id);
      if (!loan) return sendJson(res, 404, { message: 'Выдача не найдена' });
      if (loan.isExtended) return sendJson(res, 409, { message: 'Срок уже продлен' });
      loan.isExtended = true;
      loan.dueDate = '2026-11-05';
      return sendJson(res, 200, loan);
    }

    // Каталог книг
    if (path === '/api/books' && req.method === 'GET') {
      let filtered = books.filter(b => query.includeDeleted === 'true' ? b.deletedAt !== null : b.deletedAt === null);
      if (query.search) {
        const s = query.search.toLowerCase();
        filtered = filtered.filter(b => b.title.toLowerCase().includes(s) || b.isbn.toLowerCase().includes(s));
      }
      const page = parseInt(query.page || '1', 10);
      const size = parseInt(query.size || '5', 10);
      return sendJson(res, 200, { items: filtered.slice((page - 1) * size, page * size), total: filtered.length, page, size });
    }

    if (path.startsWith('/api/books/') && !path.endsWith('/restore') && req.method === 'GET') {
      const id = parseInt(path.split('/')[3], 10);
      const b = books.find(x => x.id === id);
      if (!b) return sendJson(res, 404, { message: 'Книга не найдена' });
      return sendJson(res, 200, b);
    }

    // Создание книги (POST)
    if (path === '/api/books' && req.method === 'POST') {
      const user = getAuthUser(req);
      if (!user || (user.role !== 'admin' && user.role !== 'librarian')) {
        return sendJson(res, 403, { message: 'Недостаточно прав' });
      }
      const existing = books.find(b => b.isbn.trim() === (payload.isbn || '').trim() && !b.deletedAt);
      if (existing) {
        return sendJson(res, 422, { message: 'Ошибка валидации', errors: { isbn: 'Книга с таким ISBN уже есть' } });
      }
      const newBook = {
        id: books.length > 0 ? Math.max(...books.map(b => b.id)) + 1 : 1,
        title: payload.title || '',
        isbn: payload.isbn || '',
        year: payload.year || 2026,
        pages: payload.pages || 100,
        publisherId: payload.publisherId || 1,
        authorIds: Array.isArray(payload.authorIds) ? payload.authorIds : [],
        genreIds: Array.isArray(payload.genreIds) ? payload.genreIds : [],
        copiesTotal: payload.copiesTotal || 1,
        copiesAvailable: payload.copiesAvailable !== undefined ? payload.copiesAvailable : (payload.copiesTotal || 1),
        deletedAt: null
      };
      books.push(newBook);
      return sendJson(res, 201, newBook);
    }

    // Редактирование книги (PUT)
    if (path.startsWith('/api/books/') && !path.endsWith('/restore') && req.method === 'PUT') {
      const user = getAuthUser(req);
      if (!user || (user.role !== 'admin' && user.role !== 'librarian')) {
        return sendJson(res, 403, { message: 'Недостаточно прав' });
      }
      const id = parseInt(path.split('/')[3], 10);
      const idx = books.findIndex(b => b.id === id);
      if (idx === -1) return sendJson(res, 404, { message: 'Книга не найдена' });

      const existing = books.find(b => b.id !== id && b.isbn.trim() === (payload.isbn || '').trim() && !b.deletedAt);
      if (existing) {
        return sendJson(res, 422, { message: 'Ошибка валидации', errors: { isbn: 'Книга с таким ISBN уже есть' } });
      }

      books[idx] = { ...books[idx], ...payload, id };
      return sendJson(res, 200, books[idx]);
    }

    // Удаление книги (DELETE)
    if (path.startsWith('/api/books/') && req.method === 'DELETE') {
      const user = getAuthUser(req);
      if (!user) return sendJson(res, 401, { message: 'Требуется авторизация' });
      const id = parseInt(path.split('/')[3], 10);
      const isHard = query.hard === 'true';

      if (isHard) {
        if (user.role !== 'admin') {
          return sendJson(res, 403, { message: 'Сервер отклонил операцию (403 Forbidden): Физическое удаление доступно только администратору!' });
        }
        books = books.filter(b => b.id !== id);
      } else {
        if (user.role !== 'admin' && user.role !== 'librarian') {
          return sendJson(res, 403, { message: 'Сервер отклонил операцию (403 Forbidden): У вас нет прав на удаление книг!' });
        }
        const b = books.find(x => x.id === id);
        if (b) b.deletedAt = new Date().toISOString();
      }
      return sendJson(res, 200, { success: true });
    }

    // Восстановление книги
    if (path.endsWith('/restore') && req.method === 'POST') {
      const user = getAuthUser(req);
      if (!user || user.role !== 'admin') {
        return sendJson(res, 403, { message: 'Восстановление доступно только администратору' });
      }
      const id = parseInt(path.split('/')[3], 10);
      const b = books.find(x => x.id === id);
      if (b) b.deletedAt = null;
      return sendJson(res, 200, { success: true });
    }

    return sendJson(res, 404, { message: 'Эндпоинт не найден' });
  });
});

server.listen(port, () => {
  console.log(`[Mock Server] Слушает порт ${port}, Origin: ${allowedOrigin}`);
});