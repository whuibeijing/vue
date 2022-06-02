FROM registry.cn-beijing.aliyuncs.com/hub-mirrors/node:10

COPY . .
RUN npm install -g cnpm --registry=https://registry.npm.taobao.org && cnpm install

CMD ["node", "app.js"]